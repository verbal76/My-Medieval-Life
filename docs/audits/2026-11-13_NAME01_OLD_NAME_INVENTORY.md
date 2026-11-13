# NAME-01: old-name inventory (My Medieval Life -> Forge My Life)

Workstream D of the owner's directive NAME-01 (2026-11-13, `docs/directives/2026-11-13_name01_forge_my_life_master_directive.md`,
on `wip/requirements-control`), section 5: "Search the complete project for remaining old-name references. Classify each
occurrence as player-facing, active infrastructure, internal identifier, or historical record. Do not blindly replace every
occurrence."

- **Taken:** 2026-11-13T09:44Z, branch `wip/name-01-d`.
- **Base commit:** `a5a0b7c` (Build 40, preserved). Every count below is of the tree at `a5a0b7c`, before any NAME-01 change.
- **Search:** `git grep -n -i -I "my medieval life\|mymedievallife\|my_medieval_life\|my-medieval-life\|working title\|\bthe well\b" a5a0b7c`
  over the whole tree (text files), plus `git grep -c -i -a` for binary files.
- **Method:** each match is split into its kind and classified by the rules below; a line can hold more than one occurrence.

## Totals

| Category | Occurrences | Files |
|---|---:|---:|
| Player-facing | 34 | 14 |
| Active infrastructure | 104 | 31 |
| Internal identifier | 81 | 21 |
| Historical record | 1225 | 163 |
| Not the game's name: Morris's novel *The Well at the World's End* | 3616 | 171 |
| Not the game's name: the in-game well / The Well House | 90 | 44 |
| **All** | **5150** | **412** distinct |

Matching lines (git grep -c): 4637.

**Binary files** (counted, not opened): 1 file, `My_Medieval_Life_Icon_Pack.zip`, 10 matching byte runs (its member names,
`My_Medieval_Life_<size>x<size>.png`). Source archive: read-only (CLAUDE.md section 3), **internal identifier, keep**.

Only the first four categories are old-name references. The two "not the game's name" rows are matches of the search's
`\bthe well\b` term that are not the working title *The Well*: William Morris's novel *The Well at the World's End* (the
source book of the world: `research/`, `docs/world/`, `tools/lore/`, the credits' "story" line, the wiki's settlements page)
and the village's well, a station, and the tavern The Well House (game code, data, tests, fixtures). They stay as they are.

### Remaining work by workstream (occurrences to change, at the base commit)

| Workstream | Files | What |
|---|---|---|
| A (presentation) | `game/scripts/ui/game_ui.gd` (title "My Medieval Life  (working title: The Well)", about line "My Medieval Life, by Hot Attic Games.", fallback export name `MyMedievalLife.json`), `game/scripts/core/demo.gd` (2 notes), `game/scripts/core/wiki.gd` (demo and firewall pages), `game/scripts/net/net_session.gd` (version mismatch message), `game/scripts/ui/net_window.gd` (firewall hint), `game/scripts/net/net_upnp.gd` (UPnP mapping description, seen in the router), `game/data/credits.json` (pack label "My Medieval Life icon", "made with Suno for My Medieval Life"; the `sources` zip name and music URLs stay) | Player-facing text |
| B (saves and settings) | `game/project.godot` (`config/name`, `config/description` "Working title: The Well...", header comment; `config/name` also sets the `user://` folder), `game/scripts/core/save_transfer.gd` (file filter label "My Medieval Life save", `MyMedievalLife-<name>-day<N>-<date>.json`), `game/tests/save_transfer_test.gd` (expects `MyMedievalLife-`), `game/scripts/recorder_export/live_export.gd` (`Documents/My Medieval Life/recordings`), `game/scripts/recorder_export/xlsx_writer.gd` (workbook `dc:title` "My Medieval Life simulation analysis") | Player-facing names and paths |
| C (packaging and Steam) | `game/export_presets.cfg` (export paths `MyMedievalLife*.exe/.x86_64`, `mymedievallife-dev.apk`/`-demo.apk`, `application/product_name`, Android `package/name` "My Medieval Life (dev)" and Demo; `package/unique_name` stays), `.github/workflows/release.yml` (package names `MyMedievalLife-B<n>...`, exe/bin names, release title "My Medieval Life — Build n"; the Android id checks stay), `.github/workflows/win-smoke.yml` (debugger module pattern `MyMedievalLife*`, must follow the exe rename), `game/data/steam.json` (3 texts; `app_id` is empty: 5615690), `tools/check_exe_icon.py` (docstring and usage example), `tools/checkpoint.py` (backup README title; branch names and repo URL stay), `tools/ci_report.py` (`"project"` field) | Active infrastructure and Steam texts |
| D (this branch) | done: see "Changes made by Workstream D" | Active documentation |

## Classification rules

| Category | What it covers | Decision |
|---|---|---|
| Player-facing | Text or names a player sees: window and title screen, about and credits lines, demo notes, wiki pages, network messages, the router's UPnP label, save export file names and file-type label, the export folder, workbook metadata, Steam button texts, export product names and Android labels, `config/name` | Change (A, B, C) |
| Active infrastructure | Current instructions and automation: release package names and release title, CI debugger patterns, tool docstrings and report fields, current docs (CLAUDE.md, PROJECT_MEMORY, BUILDING, ANDROID_SIGNING, SAVE_CONTINUITY, FLIGHT_RECORDER, WORLD_DESIGN_RULES header, world README, the asset skill). Also the **repository name and URLs** (`verbal76/My-Medieval-Life`, release-asset URLs in `game/data/music.json`, `game/assets/PROVENANCE.json`) and **branch names** (`staging/my-medieval-life` in CLAUDE.md, the pre-push hook, CI triggers, tools) | Names and prose: change. Repository, URLs, branch names: **keep** (directive section 4) |
| Internal identifier | Android application ids `com.hotatticgames.mymedievallife.dev` and `.demo` (export presets, release.yml checks, `tests/test_android_export.py`, `game/tests/demo_journey_test.gd`, ANDROID_SIGNING); keystore file `mymedievallife-release.jks` and alias `mymedievallife_release` (owner's secrets; never renamed); source archive and member names `My_Medieval_Life_Icon_Pack.zip` (manifest, registry, packs.json, import tool, provenance, credits `sources`); owner document file names `My_Medieval_Life_*.pdf/.docx/.md` cited by docs and tools (directive and research source files are never renamed); the pack's registry name "My Medieval Life icon" (`docs/assets/packs.json`, generated registry and manifest) | Keep |
| Historical record | Directives; past audits; past build packets, tester notes and readiness reports (Builds 7-24, with their `MyMedievalLife-build<n>-...` package names and release titles); the register, its views, reconciliation baselines and recovery records; archived handoffs; the decision log; historical design documents (GAME_DESIGN, ARCHITECTURE, DEVELOPMENT_PLAN, BUILD_16_STATUS, game-designer spec with the working title *The Well*); roadmap, expansion, Build 17 and reference notes written under the old name; research notes and owner source documents (`research/sources/My_Medieval_Life_Morris_*.md`) | Keep unchanged (directive section 4) |
| Not the game's name | Morris's novel; the in-game well and The Well House | Keep (not an old-name reference) |

## Changes made by Workstream D

| File | Change | Kept on purpose |
|---|---|---|
| `CLAUDE.md` | Title "Forge My Life: project instructions"; studio "Hot Attic Games LLC"; a NAME-01 paragraph in section 1 (name, what stays, package names, Steam App ID 5615690); section 1's description starts "Forge My Life is..." | Repository name, the 9 `staging/my-medieval-life` branch references, the novel reference, the Builds table (past builds) |
| `docs/PROJECT_MEMORY.md` | "What the project is" names Forge My Life, Hot Attic Games LLC, the rename, and that the repository and Android id stay | Branch names, repository, directive PDF file names |
| `docs/WORLD_DESIGN_RULES.md` | Header line "for Forge My Life (named My Medieval Life when the rules were written)" | PDF/docx file names; the owner's quoted words at line 235 ("My Medieval Life is about people living autonomous lives.") are a verbatim quote |
| `docs/world/README.md` | "*Forge My Life*'s world (the game was called *My Medieval Life* when this was built)" | Everything else (research) |
| `.claude/skills/asset-integration-pipeline/SKILL.md` | Description "Forge My Life's asset pipeline (the game formerly My Medieval Life)" | - |
| `docs/release/BUILDING.md` | Title; local export paths `ForgeMyLife.x86_64` / `ForgeMyLife.exe` / `forgemylife-dev.apk` (as Workstream C set the presets); a paragraph naming the release packages `ForgeMyLife-B<n>-Android.apk / -Windows.zip / -Linux.zip`, the kept Android id and Steam App ID 5615690 | The icon zip name |
| `docs/release/ANDROID_SIGNING.md` | Signature file name `ForgeMyLife-B<n>-Android-signature.txt` (release.yml derives it from the APK name) | Keystore file and alias, package id |
| `docs/release/SAVE_CONTINUITY.md` | Storage folder `app_userdata/Forge My Life` (Linux and Windows) | - |
| `docs/SYSTEM_INTERACTION_MANIFEST.md` | INT-688: the Steam button now follows `steam.json`'s `app_id` 5615690 (Workstream C): "Wishlist on Steam", the game's store page (public status unconfirmed); the old "Coming Soon" behaviour recorded as before NAME-01 | In-game well references |
| `docs/design/FLIGHT_RECORDER.md` | Recorder folders `app_userdata/Forge My Life/recorder`, export folder `Documents/Forge My Life/recordings` | - |

The two storage-path docs assume Workstream B sets `config/name="Forge My Life"` without a custom user directory, and that
`live_export.gd` writes `Documents/Forge My Life/recordings`; if B chooses otherwise, those lines follow B.

Not changed and why (active-looking documents): `docs/CURRENT_DEVELOPMENT_STATE.md`, `docs/requirements/SCHEMA.md`,
`docs/release/flight_recorder/README.md`, `docs/HANDOFF.md`, `docs/release/LONG_RUN_SIMULATION.md`,
`docs/release/SIMULATION_PERFORMANCE.md` hold only branch names or repository URLs (kept); `docs/EXPANSION_ROADMAP.md` only
directive file names (kept); `docs/world/MAGIC_RESEARCH.md` is a dated research record of an owner direction (kept);
`docs/GAME_DESIGN.md` and `docs/ARCHITECTURE.md` are historical reference by CLAUDE.md section 1 (their "Title: My Medieval
Life" rows record the decision of the time; NAME-01 supersedes them in the register, the lead's task: see REC-005 below).

## For the lead (register, not edited here)

- **REC-005** "Working title 'The Well'; repository, package and identifiers stay My Medieval Life" (OWNER APPROVED,
  COMPLETE) is superseded in part by NAME-01: the player-facing name is now Forge My Life; the repository and Android id
  still stay. It needs a history line or SUPERSEDED-by-NAME-01 note on the records branch. `docs/DEVELOPMENT_LEDGER.md` and
  the views regenerate from the register.
- The authoritative `CLAUDE.md` is on `wip/requirements-control` (this branch's copy carries a stale-copy notice); the
  same NAME-01 paragraph belongs there.

## Every file and group

Groups (one row) stand for many files of one kind. "Kind": `branch` = `staging/` or `origin/my-medieval-life`, `repo` =
`My-Medieval-Life` in a URL or name, `filename` = `My_Medieval_Life_*`, `pkgid` = the Android id, `package` = other
`mymedievallife` (package and file names), `prose` = "My Medieval Life", `worktitle` = "working title", `well` = "the well".

| File or group | Files | Occurrences by category (kind) | Owner | Action |
|---|---:|---|---|---|
| `.claude/skills/asset-integration-pipeline/SKILL.md` | 1 | Active infrastructure prose 1 | D | Updated by D (this branch); kept parts listed below |
| `.github/workflows/release.yml` | 1 | Active infrastructure package 18, Active infrastructure prose 1, Internal identifier pkgid 2 | C | Change: Workstream C |
| `.github/workflows/requirements.yml` | 1 | Active infrastructure branch 2 | C | Keep |
| `.github/workflows/tests.yml` | 1 | Active infrastructure branch 3 | C | Keep |
| `.github/workflows/win-smoke.yml` | 1 | Active infrastructure package 1 | C | Change: Workstream C |
| `ASSET_MANIFEST.md` | 1 | Internal identifier filename 6 | D | Keep |
| `CLAUDE.md` | 1 | Active infrastructure branch 9, Active infrastructure prose 2, Active infrastructure repo 2, Not the game's name (novel) well 1 | D | Updated by D (this branch); kept parts listed below |
| `asset_manifest.csv` | 1 | Internal identifier filename 18 | D | Keep |
| `data/asset_registry.json` | 1 | Internal identifier filename 11, Internal identifier prose 1 | D | Keep |
| `docs/ARCHITECTURE.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/BUILD_16_STATUS.md` | 1 | Historical record branch 1, Historical record repo 1 | D | Keep |
| `docs/BUILD_DECISIONS.md` | 1 | Historical record well 2 | D | Keep |
| `docs/CURRENT_DEVELOPMENT_STATE.md` | 1 | Active infrastructure branch 2 | D | Keep |
| `docs/DECISIONS.md` | 1 | Historical record branch 3, Historical record filename 1, Historical record pkgid 1, Historical record prose 2, Not the game's name (novel) well 2, Not the game's name (in-game well) well 5 | D | Keep |
| `docs/DESIGN_GAP_ASSESSMENT.md` | 1 | Not the game's name (novel) well 3, Not the game's name (in-game well) well 1 | D | Keep |
| `docs/DEVELOPMENT_LEDGER.md` | 1 | Historical record prose 1, Historical record well 1, Historical record worktitle 1 | D | Keep |
| `docs/DEVELOPMENT_PLAN.md` | 1 | Historical record branch 1, Historical record prose 1 | D | Keep |
| `docs/EXPANSION_ROADMAP.md` | 1 | Internal identifier filename 4 | D | Keep |
| `docs/GAME_DESIGN.md` | 1 | Historical record prose 3, Not the game's name (novel) well 1 | D | Keep |
| `docs/HANDOFF.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/LIVING_WORLD_ALIGNMENT.md` | 1 | Not the game's name (novel) well 1 | D | Keep |
| `docs/PROJECT_MEMORY.md` | 1 | Active infrastructure branch 2, Active infrastructure prose 1, Active infrastructure repo 1, Internal identifier filename 3 | D | Updated by D (this branch); kept parts listed below |
| `docs/SYSTEM_INTERACTION_MANIFEST.md` | 1 | Not the game's name (in-game well) well 6 | D | Keep |
| `docs/WORLD_DESIGN_RULES.md` | 1 | Active infrastructure prose 2, Internal identifier filename 2 | D | Updated by D (this branch); kept parts listed below |
| `docs/assets/ASSET_REGISTRY.md` | 1 | Internal identifier filename 1, Internal identifier prose 2 | D | Keep |
| `docs/assets/packs.json` | 1 | Internal identifier filename 1, Internal identifier prose 1 | D | Keep |
| docs/audits/** (past verification reports) | 15 | Historical record repo 30 | - | Keep |
| `docs/build17/BUILD_17_PLAN.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/DEPOSIT_SUSTAINABILITY.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/MIN_B_QUARRY.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/MIN_C_PROSPECTING.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/MIN_D_DISCOVERY.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/MIN_E_OPEN_PIT.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/MIN_F_UNDERGROUND.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/PROCUREMENT_CONTRACTS.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/build17/STONE_01_BLOCKS.md` | 1 | Not the game's name (in-game well) well 2 | D | Keep |
| `docs/build17/UNDERGROUND_ARCHITECTURE.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/design/FARM_STALL_AUDIT.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/design/FLIGHT_RECORDER.md` | 1 | Active infrastructure prose 3 | D | Updated by D (this branch); kept parts listed below |
| `docs/design/HOMESTEADING_B25R1.md` | 1 | Not the game's name (in-game well) well 2 | D | Keep |
| `docs/design/SIM_GATE_AUDIT.md` | 1 | Historical record prose 1 | D | Keep |
| docs/directives/** (owner directives, verbatim) | 58 | Historical record branch 3, Historical record filename 20, Historical record prose 96, Historical record repo 9 | - | Keep |
| `docs/expansion18/CLOSEOUT_SET_A_B_C_WDR002.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion18/DESIGN.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion18/SETTLEMENTS.md` | 1 | Not the game's name (novel) well 1 | D | Keep |
| `docs/expansion19/DESIGN.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion20/LE00_ARCHITECTURE_AUDIT.md` | 1 | Historical record branch 1, Historical record filename 1 | D | Keep |
| `docs/expansion20/LE00_BUILD18_REFRESH.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion20/LE01_IMPLEMENTATION.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion20/LE02_IMPLEMENTATION.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion20/LE03_IMPLEMENTATION.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion20/SJDG_SOAK_REPORT.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/expansion20/X18_X20_COVERAGE_MATRIX.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/expansion21/P21_READINESS.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/game-designer/MASTER_PROMPT.md` | 1 | Historical record well 6 | D | Keep |
| `docs/game-designer/README.md` | 1 | Historical record well 1, Historical record worktitle 1 | D | Keep |
| `docs/game-designer/SPEC_RECONCILIATION.md` | 1 | Historical record package 1, Historical record pkgid 2, Historical record prose 4, Historical record well 10, Historical record worktitle 2, Not the game's name (novel) well 2 | D | Keep |
| `docs/game-designer/THE_WELL_SPEC_v1.md` | 1 | Historical record well 7 | D | Keep |
| `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-23.md` | 1 | Historical record branch 6, Historical record filename 1, Historical record repo 2 | D | Keep |
| `docs/handoffs/archive/CURRENT_SESSION_RECOVERY_to_2026-10-23.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/multiplayer/BATCH_A.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/reference/DESIGNING_VIRTUAL_WORLDS.md` | 1 | Historical record prose 1, Not the game's name (in-game well) well 1 | D | Keep |
| `docs/reference/designing_virtual_worlds/notes_A.md` | 1 | Historical record prose 2, Historical record repo 1 | D | Keep |
| `docs/reference/designing_virtual_worlds/notes_B.md` | 1 | Historical record prose 2 | D | Keep |
| `docs/reference/designing_virtual_worlds/notes_CD.md` | 1 | Historical record prose 2, Not the game's name (in-game well) well 1 | D | Keep |
| `docs/reference/designing_virtual_worlds/notes_E.md` | 1 | Historical record prose 1, Not the game's name (novel) well 1, Not the game's name (in-game well) well 1 | D | Keep |
| `docs/reference/designing_virtual_worlds/notes_F1.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/reference/designing_virtual_worlds/notes_F2.md` | 1 | Historical record prose 1, Not the game's name (novel) well 1, Not the game's name (in-game well) well 2 | D | Keep |
| `docs/release/ANDROID_SIGNING.md` | 1 | Active infrastructure package 1, Internal identifier package 2, Internal identifier pkgid 1 | D | Updated by D (this branch); kept parts listed below |
| `docs/release/AUDIT_REMEDIATION.md` | 1 | Historical record branch 4, Historical record filename 1, Historical record repo 1 | D | Keep |
| `docs/release/BUILDING.md` | 1 | Active infrastructure package 4, Active infrastructure prose 1, Internal identifier filename 1 | D | Updated by D (this branch); kept parts listed below |
| docs/release/BUILD_*.md (past build packets, tester notes, audits) | 20 | Historical record branch 18, Historical record package 33, Historical record prose 13, Historical record repo 27, Not the game's name (in-game well) well 1 | - | Keep |
| `docs/release/LONG_RUN_SIMULATION.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/release/OVERNIGHT_REPORT_2026-10-20.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/release/SAVE_CONTINUITY.md` | 1 | Active infrastructure prose 2 | D | Updated by D (this branch); kept parts listed below |
| `docs/release/SIMULATION_PERFORMANCE.md` | 1 | Historical record branch 1 | D | Keep |
| `docs/release/flight_recorder/README.md` | 1 | Active infrastructure repo 4 | D | Keep |
| docs/requirements/** (register, views, reconciliation baselines, recovery records) | 6 | Historical record branch 678, Historical record filename 146, Historical record pkgid 1, Historical record prose 3, Historical record repo 4, Historical record well 4, Historical record worktitle 5, Not the game's name (in-game well) well 3 | - | Keep |
| `docs/roadmap/18_SETTLEMENTS_ENGINEERING_PLAN.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/roadmap/19_SJD_RECONCILIATION.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/roadmap/21_Politics.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/roadmap/22_Bandits.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/roadmap/23_Legacy.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/roadmap/23_Legacy_comparison.md` | 1 | Historical record filename 1 | D | Keep |
| `docs/roadmap/Documentation_Index.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/roadmap/Exploration_Combat.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/roadmap/MULTIPLAYER_BRANCH_AUDIT.md` | 1 | Historical record branch 2 | D | Keep |
| `docs/roadmap/Master_Expansion_Roadmap.md` | 1 | Historical record filename 9, Historical record prose 1 | D | Keep |
| `docs/roadmap/Multiplayer.md` | 1 | Historical record prose 1 | D | Keep |
| `docs/systems/RESOURCE_NODE_MANIFEST.md` | 1 | Not the game's name (in-game well) well 1 | D | Keep |
| docs/world/** (Morris knowledge base; mostly generated) | 11 | Historical record prose 1, Not the game's name (novel) well 176 | - | Keep |
| `docs/world/README.md` | 1 | Active infrastructure prose 1, Not the game's name (novel) well 1 | D | Updated by D (this branch); kept parts listed below |
| `game/assets/PROVENANCE.json` | 1 | Active infrastructure repo 3, Internal identifier filename 8 | A | Keep |
| `game/data/credits.json` | 1 | Active infrastructure repo 3, Internal identifier filename 1, Not the game's name (novel) well 1, Player-facing prose 2 | A | Change: Workstream A |
| `game/data/music.json` | 1 | Active infrastructure repo 5 | A | Keep |
| `game/data/resources.json` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/data/settlements.json` | 1 | Not the game's name (novel) well 1 | A | Keep |
| `game/data/steam.json` | 1 | Player-facing prose 3 | C | Change: Workstream C |
| `game/data/village.json` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/export_presets.cfg` | 1 | Active infrastructure package 6, Internal identifier pkgid 2, Player-facing prose 4 | C | Change: Workstream C |
| `game/project.godot` | 1 | Player-facing prose 2, Player-facing well 2, Player-facing worktitle 2 | B | Change: Workstream B |
| `game/scripts/core/business_desks.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/core/demo.gd` | 1 | Player-facing prose 2 | A | Change: Workstream A |
| `game/scripts/core/farming.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/core/judgment/judgment_store.gd` | 1 | Internal identifier filename 1 | A | Keep |
| `game/scripts/core/manor_work.gd` | 1 | Not the game's name (in-game well) well 2 | A | Keep |
| `game/scripts/core/property.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/core/save_transfer.gd` | 1 | Player-facing package 1, Player-facing prose 1 | B | Change: Workstream B |
| `game/scripts/core/settlement/offmap.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/core/settlement/regions.gd` | 1 | Not the game's name (in-game well) well 2 | A | Keep |
| `game/scripts/core/wiki.gd` | 1 | Not the game's name (in-game well) well 1, Player-facing prose 2 | A | Change: Workstream A |
| `game/scripts/core/wiki_manor.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/core/wiki_topics.gd` | 1 | Not the game's name (novel) well 1, Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/core/wilds.gd` | 1 | Not the game's name (in-game well) well 7 | A | Keep |
| `game/scripts/core/world.gd` | 1 | Not the game's name (in-game well) well 3 | A | Keep |
| `game/scripts/main.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/net/net_session.gd` | 1 | Player-facing prose 1 | A | Change: Workstream A |
| `game/scripts/net/net_upnp.gd` | 1 | Player-facing prose 1 | A | Change: Workstream A |
| `game/scripts/recorder_export/live_export.gd` | 1 | Player-facing prose 2 | B | Change: Workstream B |
| `game/scripts/recorder_export/xlsx_writer.gd` | 1 | Player-facing prose 2 | B | Change: Workstream B |
| `game/scripts/ui/game_ui.gd` | 1 | Player-facing package 1, Player-facing prose 2, Player-facing well 1, Player-facing worktitle 1 | A | Change: Workstream A |
| `game/scripts/ui/inventory_window.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/scripts/ui/net_window.gd` | 1 | Player-facing prose 1 | A | Change: Workstream A |
| `game/scripts/ui/wanted_hud.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/tests/audio_test.gd` | 1 | Active infrastructure repo 1 | A | Keep |
| `game/tests/demo_journey_test.gd` | 1 | Internal identifier pkgid 1 | A | Keep |
| `game/tests/economy_sim.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| game/tests/fixtures/*.json (old save fixtures) | 8 | Not the game's name (in-game well) well 9 | - | Keep |
| `game/tests/homestead_shot.gd` | 1 | Not the game's name (in-game well) well 8 | A | Keep |
| `game/tests/mp_interact_ui_test.gd` | 1 | Not the game's name (in-game well) well 4 | A | Keep |
| `game/tests/player_homestead_test.gd` | 1 | Not the game's name (in-game well) well 4 | A | Keep |
| `game/tests/run_tests.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/tests/save_transfer_test.gd` | 1 | Player-facing package 1 | B | Change: Workstream B |
| `game/tests/start_test.gd` | 1 | Not the game's name (in-game well) well 1 | A | Keep |
| `game/tests/wilds_test.gd` | 1 | Not the game's name (in-game well) well 7 | A | Keep |
| research/** (novel corpus, sources, extractions, registries, notes) | 144 | Historical record prose 2, Not the game's name (novel) well 3415 | - | Keep |
| `tests/test_android_export.py` | 1 | Internal identifier pkgid 2 | C | Keep |
| `tools/branch_audit.py` | 1 | Active infrastructure branch 1 | C | Keep |
| `tools/build_manifest.py` | 1 | Internal identifier filename 1 | C | Keep |
| `tools/build_village.py` | 1 | Not the game's name (in-game well) well 3 | C | Keep |
| `tools/check_exe_icon.py` | 1 | Active infrastructure package 1, Active infrastructure prose 1 | C | Change: Workstream C |
| `tools/check_requirements.py` | 1 | Active infrastructure branch 2 | C | Keep |
| `tools/checkpoint.py` | 1 | Active infrastructure branch 2, Active infrastructure prose 1, Active infrastructure repo 1 | C | Change: Workstream C |
| `tools/ci_report.py` | 1 | Active infrastructure prose 1 | C | Change: Workstream C |
| `tools/fetch_music.py` | 1 | Active infrastructure repo 1 | C | Keep |
| `tools/game_audio.py` | 1 | Active infrastructure repo 1 | C | Keep |
| `tools/git_hooks/pre-push` | 1 | Active infrastructure branch 7 | C | Keep |
| `tools/import_game_assets.py` | 1 | Internal identifier filename 5 | C | Keep |
| `tools/living_forest.py` | 1 | Active infrastructure repo 2 | C | Keep |
| `tools/lore/audit_documents.py` | 1 | Internal identifier filename 2 | C | Keep |
| `tools/lore/build_corpus.py` | 1 | Internal identifier filename 2, Not the game's name (novel) well 2 | C | Keep |
| `tools/lore/build_novel.py` | 1 | Not the game's name (novel) well 5 | C | Keep |
| `tools/lore/render_world_docs.py` | 1 | Not the game's name (novel) well 1 | C | Keep |
| `tools/requirements_audit.py` | 1 | Active infrastructure branch 1 | C | Keep |
| `tools/requirements_migrate.py` | 1 | Historical record filename 1 | C | Keep |
| `tools/requirements_migrate_v2.py` | 1 | Historical record branch 1 | C | Keep |
| `tools/requirements_update.py` | 1 | Active infrastructure branch 1 | C | Keep |
