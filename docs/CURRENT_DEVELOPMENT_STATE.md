# Current development state (start here)

**This is the one current-state document.** Owner directives MEM-01 and DOC-CONT-01 make it the entry point.

- **Updated:** 2026-11-03 (Build 25 Revision 1 in progress).
- **Snapshot last verified:** 2026-11-03 01:10 UTC by the lead, against wip/region-nav `aafcc4d`, wip/expansion20 `4b51c92` (campaigns 41536805310 and 41536810831 running), wip/requirements-control (this commit).
  - **Convention:** whoever checks this file against the live GitHub state writes this line as
    `YYYY-MM-DD HH:MM UTC by <session or agent>, against wip/expansion20 <sha>, wip/requirements-control <sha>, Actions runs
    to <newest run id>`.
  - It is rewritten at each checkpoint; earlier stamps live in git history.
  - A reader who finds newer commits or runs than the stamp names must treat this file as stale where they disagree. See
    `docs/handoffs/CURRENT_SESSION_RECOVERY.md`, step 3.
  - Defects and investigations: `docs/KNOWN_ISSUES.md`. Decision rationale: `docs/decisions/`.
- **Where the authoritative copy lives:** branch `wip/requirements-control`. The owner keeps that branch isolated, so copies of this
  file on `staging/my-medieval-life`, `wip/expansion20` and older branches are stale. Each of those copies carries a banner saying so.
- **What this file holds:** session state only.
  - Requirement and decision status lives in the register, `docs/requirements/requirements.json`, with generated views in
    `docs/requirements/views/`.
  - History lives in `docs/DEVELOPMENT_CHANGELOG.md`.
- **Recovery after lost context:** `docs/handoffs/CURRENT_SESSION_RECOVERY.md`.

## Owner decision 2026-11-05: B25R1 audit, Option 1 (B25R1-AUDIT-OPT1; controls this session)

- **Directive:** `docs/directives/2026-11-05_b25r1_audit_option1.md`. Finish validating the current code (`wip/b25r1`, head `a995397`)
  while developing every approved B25R1 requirement; no deferral without the owner. The audit
  `docs/audits/B25R1_REQUIREMENTS_AUDIT_2026-11-05.md` is the working completion checklist.
- **Live completion report:** `docs/handoffs/B25R1_COMPLETION_REPORT.md` (counts, per-requirement table, SHAs and runs, what to repeat
  when the final SHA changes). **Owner questions** (seven groups, asked one at a time): `docs/handoffs/B25R1_OWNER_QUESTIONS_2026-11-05.md`.
- **New register ids (in development, grass-and-map worker, branch wip/b25r1-grassmap once created):** B25R1-023 Bow.Pixel Low Grass
  decoration on the overworld; B25R1-024 region map restyle (UIStyle, gamepad focus on the Village tab).
- **Economy decisions (owner 2026-11-05, questions 20-27):** B25-ECON-P1..P3 integrated (edf1854); B25-ECON-P5 land clearing integrated (c3d9d91); B25-ECON-P4 own-settlement ore consignment integrated (c3d9d91), cross-settlement consignment (owner question 27) in development on wip/b25r1-econ3.
- **Other ordered work (Option 1 item 2):** B25R1-018 Bear Hill and castle knoll; B25R1-022 Fantasy Lands houses; B25R1-010 player
  homestead well; B25R1-020 Android crowd-management measurement. EA-01 tracked separately (milestone: Early Access demo about
  2026-11-24; build placement is the owner's).

## Build 25 Revision 1 (owner, 2026-11-03)

- **Directives:** `docs/directives/2026-11-03_b25r1_master_directive.md` (B25R1-001..008), `2026-11-03_b25r1_seed_travelers.md` (B25R1-009), `2026-11-03_b25r1_homesteading.md` (B25R1-010), `2026-11-03_b25r1_road_wear.md` (B25R1-011), `2026-11-03_b25r1_owner_clarifications.md` (B25R1-012 and clarifications), `2026-11-03_b25r1_youth_runaways.md` (B25R1-013), `2026-11-03_b25r1_outlaw_communities.md` (B25R1-014, the four decisions), `2026-11-03_b25r1_full_scope_mandatory.md` (B25R1-015), `2026-11-03_b25r1_365_day_flight_recorder.md` (B25R1-016), `2026-11-03_b25r1_integration_water_directive.md` (B25R1-017), `2026-11-03_b25r1_regional_world_reconstruction.md` (B25R1-018); owner answers B25R1-Q2 (band moves to the wild) and Q3 (streams and wells), Q4 (defenders fight or flee, no surrender), Q5 (no save migration: the owner erases saves at each play test), Q6 and Q7 (presence by view range, everywhere including the village).
- **Scope rule (B25R1-015, owner 2026-11-03):** every approved B25R1 function ships in Revision 1, working, with its switches on in the shipped configuration. Nothing is deferred, disabled, replaced by a placeholder or narrowed without an owner decision. Blockers go to the owner with obstacle, systems, solutions, recommendation and consequences; unblocked work continues. The Revision 1 draft is not ready until all of it is implemented, integrated and validated.
- **Living-world proof (B25R1-016, owner 2026-11-03):** one continuous 365-day flight-recorder campaign (about 45.6 game years) on the final integrated candidate, normal rules, built on the existing recorder (REC-19, `mml-recorder/2`, its design note in `docs/design` on `wip/b25r1`, the campaign workflow). Deliverables: executive report, migration, bandit, homestead and economic ledgers, life histories A-G, line and scatter charts, exception report, evidence index, retained as Actions artifacts. Rare features unobserved organically get labelled targeted scenarios. Instrumentation: each worker records its own systems; the recorder worker (`wip/b25r1-recorder`, base `wip/b25r1`) owns the recorder, the merged systems' hooks (roads, travel, landmarks), the report generator and the workflow. The campaign runs once, after every system is merged; never restart it for reassurance (SIM-01, SIM-02).
- **Rollback point:** the Build 25 private draft (`build-25`, release id 432836586, from `a459186`, run 41666958781). Never overwritten: Revision 1 gets its own draft (use `build_number` other than 25, e.g. 26 or a distinct tag; check release.yml's tag naming before dispatching).
- **Integration branch:** `wip/b25r1`, head `c5299cd` (pushed).
- **Overnight 2026-11-03/04 (owner low-token mode):** one active agent, the integration coordinator, on `wip/b25r1`. It merges region `9ce9a2e`, settle `084d4f0`, homestead `8da7e1f` (all 5 homestead CI items fixed), presence `711d59d` (start, refuge, housing fixed); fixes small integration failures; then dispatches Tests and the gate on the integrated SHA, re-records the baseline only if the gate's blocking findings are baseline differences alone, and launches the 365-day `--twin` campaign once. the CI parallel-testing branch (wip/ b25r1-ci, being pushed) merged only if validated. No packaging overnight. Morning report: an OVERNIGHT_2026-11-04 note under docs/handoffs on the integration branch. Pending art work after the merge: Bow.Pixel grass decoration; Fantasy Lands houses as a southern regional style (B25R1-022); region map restyle.
- **Playtest readiness (2026-11-04):** `wip/b25r1` head `edc32c7` (code `2677ea7`); report PLAYTEST_READINESS_B25R1 under docs/handoffs on that branch. Fixed: recorder neutrality (`2677ea7`), homesteads with presence (`f86ba3c`), hamlet roads and stone share (`0c1aeb3`), Q9 civic policy (`b905aa9`), courier, campfire, recorder_test. Open: homestead sowing (A), raid walk with the camp by the village (A), new-household save in run_tests (B, blocks a playtest), net_fauna (A, multiplayer), regional_food script error; gate 41872734897 timed out at 120 min (slowdown to measure before re-running); no baseline re-recorded, no 365-day campaign. Awaiting the owner's playtest decision.
- **Latest audit:** `docs/audits/B25R1_PROGRESS_AUDIT_2026-11-03.md` (19:53 EST): integration about 35%, validation about 10% (estimates); integration worker merging water, region, settle, homestead, presence onto `wip/b25r1`.
- **Status by stage (B25R1-017 reporting):**
  - Implemented and merged into `wip/b25r1`: B25R1-002 interaction (lead), 003-006 map and travel, 007-008 UI, 004/011/Q1 roads, wear and paving, 012 gamepad map, 009 seed travelers (`b329da0`, INT-696), the recorder vocabulary and adapters (`315e7c8`; adapters at `f9bbd26` on `wip/b25r1-recorder`, not yet merged).
  - Implemented, not merged: `wip/b25r1-homestead` `a08f8e3`: life decisions (homestead, runaway, recruit answer, bandit leave) on, farming on claims, firewood sales, recorder calls, INT-702.
  - Under test: nothing running on the lead's side. A 240-day measurement from the first homestead worker is running locally on older code (do not stop it).
  - Validated on `c5299cd`: run_tests 3602/0, seed_traveler 48/0, gamepad_map 19/0, outside_interact 23/0, recorder 214/0, road_wear 40/0, check_interactions 0 problems. Credits regression diagnosed: test infrastructure. credits.json is unchanged since Build 25; the new road tile's provenance names two credited packs as one string, so the check now splits it and still requires every pack.
  - Outstanding: band to the wild with save migration, overworld combat and pursuit, remote animals, wells and water needs, livestock on claims, hidden workshops and markets, outlaw crafting, raids, allegiance changes (worker `wip/b25r1-homestead`, second worker); streams, rivers, waterfalls, bridges, the water query and extension points (worker `wip/b25r1-water`); the report generator, scenario harness and campaign workflow (worker `wip/b25r1-recorder`); region map restyle (lead); final candidate, sim gate, the 365-day campaign, then the private draft.
- **Workstreams:**
  - `wip/b25r1-homestead` (second worker, after the first ran out of context): the remaining B25R1-010/013/014 scope and Q2; owns households, family, faction and life decisions.
  - `wip/b25r1-water` (map and roads worker): B25R1-Q3 and 017 streams on new worlds (generator version bump, old worlds keep their maps), bridges, `Overworld.is_water(cell)` / `nearest_water(cell, radius)`.
  - `wip/b25r1-region` (worker): B25R1-018 regional reconstruction. Phase 1 is a design doc (classification A/B/C, J-D2 and J-G1, layout, hamlet count, population architecture measured, saves) and the layout data the water worker reads; then geography, settlements and hamlets, validation with drone views.
  - `wip/b25r1-presence` (worker): B25R1-019 one shared presence system, amended by B25R1-020 (anticipatory crowd management in the off-screen buffer; protected NPCs never moved; soft visible target): live within the view plus a margin (grows with zoom), calculated beyond it, for people, animals, water animation and tree sway; the village re-validated on it; sim gate re-baselined.
  - `wip/b25r1-recorder` (worker): B25R1-016 reports A-I (a flight_lives tool under tools/ on that branch), scenario harness, chained 365-day campaign workflow with a determinism twin.
- **Lead next:** region map restyle with `UIStyle` and the pad focus on the Village tab; merge the homestead, water and recorder branches as they report; final candidate with focused suites, the sim gate on that exact commit, and screenshots at 1280x720 and 2400x1080; then a separate private six-package draft recorded in `docs/release/build25_reconciliation/CI_RECORD.md`.

## Overnight autonomous development (owner, 2026-11-02, B25-OVN-0211; controls this session)

Directive: `docs/directives/2026-11-02_overnight_autonomous_development_directive.md`.
- **Operating rules:**
  - Broad engineering discretion within the owner's rules.
  - Several independent workstreams where they don't share files.
  - Never idle on one question: record it with options and continue elsewhere.
  - GitHub Actions does the heavy runs.
  - This replaces reduced-resource mode's one-worker limit.
- **Owner answer:** B25-BIZ-TENANT-Q is APPROVED as Option B. It is implemented on the Build 25 source at `3c7e45b`:
  - A rented home satisfies "a house first" for a standalone workshop on bought ground.
  - Additions to a house stay the owner's.
  - Reopening or buying a workshop needs no owned home.
- **On return the owner wants a consolidated report:** completed, in progress, economic findings, decisions, next.

## Position

| Item | Value |
|---|---|
| Current development build | **Build 25**, the consolidation build. It holds all approved expansion work and all approved recoverable abandoned-branch work (B25-SCOPE-D1, `docs/directives/2026-11-01_build25_scope_clarification.md`). |
| Integration branch (Build 25 source) | `wip/expansion20`, the **one** code integration branch (BRANCH-POL-01, owner 2026-11-02; CLAUDE.md section 5a). Task branches start from its head and are merged back promptly after `branch_audit.py --worktrees` (run on `wip/expansion20`). |
| Development head | **`4b51c92` FROZEN Build 25 candidate** (B25-CLOSE-02): farming Phase 2 (yield 1.75, shared and seasonal farming on, old-save seed corn), the cart-hitch fix and the simulator's resume counters, fast-forwarded from `wip/b25-farm-phase2`; on `34e1041` (KI-HOME-DOOR). Nothing else lands on `wip/expansion20` while the final campaign runs. |
| Latest verified SHA | `3c7e45b`: suites TESTED locally, listed below. No CI run, no 30-day baseline and no year-long run on this SHA. The last SHA with year-long CI evidence is `ae8641d` (chapel fix). The last SHA with a complete validated gate is `ad281dc` (30-day baseline). Its year-long runs failed on the gossip crash, which is now fixed. |
| Rollback point | `ad281dc` |
| Records branch | `wip/requirements-control`. It holds the register, directives and this file. The register is edited only here, with `tools/requirements_update.py` and then `tools/check_requirements.py --write`. It is not merged into staging or `wip/expansion20` without the owner's authorization. |
| `staging/my-medieval-life` | `baa6479` (2026-11-01). **Historical** (BRANCH-POL-01): the old records lineage. Its 447 commits not on `wip/expansion20` are records history, not unmerged code. Never merged into the integration branch. |
| Latest packaged build | Build 24: commit `4611d86`, run 40636966840, private three-platform draft. Frozen. There is no `build-24` git tag; the draft release is the record. Builds 22 and 23 are frozen. |
| Packaging and release | No Build 25 package exists. Packaging needs the owner's authorization. No public release. |
| Living Economy | Integrated but **off** by default. It switches on by default once the 13 LE-07 readiness gates pass on the integrated candidate, with no further approval (B25-LE-ACTIVATE-D1). |
| Operating mode | **STANDBY** (owner, 2026-11-02, MML-CONSERVE-01): MML is second priority behind Upwardly. At most one Claude worker; no parallel investigators, background sessions, scheduled follow-ups, new features or 365-day campaigns without the owner's approval. Nothing is being worked on. |
| GitHub Actions | **Running, the one final campaign (owner B25-CLOSE-02) on `4b51c92`:** flight [41536805310](https://github.com/verbal76/My-Medieval-Life/actions/runs/41536805310) (seeds 1 and 2, 365 days, every 10, 100-day segments, recorded) and economy-on [41536810831](https://github.com/verbal76/My-Medieval-Life/actions/runs/41536810831) (seed 1, `--market`, 365 days, every 10). Do not cancel, rerun or duplicate (SIM-02). Done: Tests 41509578455 on `0d194c8` green (full CI, reused). |

## Workers and branches (recovery records)

**File ownership (BRANCH-POL-01, 2026-11-02).** Merge order: KI-HOME-DOOR first, then farming Phase 2 (which merges the integration branch in before submitting).
- **Home-door:** `npc_brain.gd` (evening and home logic), `construction.gd` (home and resident handling), `world.gd` (`building_door` and the home-reference helpers), `home_ref_test.gd`.
- **Farming Phase 2:** `balance.json`, `farming.gd`, `population.gd`, `wiki.gd`, `wiki_farming.gd`, the farm tests, `resources.json` and its generated files, `FARMING_YIELD_CALIBRATION.md`, and the farming code in `world.gd`.
- **Shared:** `docs/DECISIONS.md` and `SYSTEM_INTERACTION_MANIFEST.md`; each worker edits only its own entries.
- **The investigation** owns nothing and commits nothing.

Every branch below holds real, unmerged work. None is disposable.

| Worker or workstream | Register | Branch / worktree | Latest pushed | Unpushed | State and tests | Merge readiness | Next safe step |
|---|---|---|---|---|---|---|---|
| **ACTIVE (lead):** DEMO-01 (owner 2026-11-03: 120-minute demo, Steam promotion, six packages; checklist section I) and Build 25 completion (B25-FINISH-01, owner 2026-11-03): fixed checklist `docs/release/build25_reconciliation/COMPLETION_CHECKLIST.md`; regional economy REGION-NAV-01 | B25-FINISH-01, REGION-NAV-01, DEMO-01 | `wip/region-nav`; worktree `.claude/worktrees/region-nav` | `d13668d` | none | Validation defects D1-D4 fixed (`8792886`, `b18f418`); S3 blocked-route and death code and journey_s3_test 19/0 (`b18f418`); records `5e3b803`. S2 suite pass on `b18f418` finishing. Then KI-RECOVER-LOOT, S4-S8, gate 9 review, merge, activation, candidate CI, final flight, packages (checklist order). | not for merge yet | Report S2 and S3 |
| **ACTIVE (one read-only agent, VAL-AGENT-01):** S2 validation | VAL-AGENT-01 | detached checkout `.claude/worktrees/region-nav-validate` at `d3b82c4` | — | none | Reviews S2 code, tests and evidence; reports verified, unverified, defects, risks, actions to the lead. Edits nothing. | report only | The lead records findings and owns fixes. |
| Merged: farming yield Phase 2, cart-hitch fix | FARM-YIELD-D1, B25-CLOSE-01/02 | `wip/b25-farm-phase2` `4b51c92`, fast-forwarded into `wip/expansion20` | `4b51c92` | none | Targeted suites green (see the register, B25-CLOSE-02). | merged | none |
| Merged: KI-HOME-DOOR fix | FR-REPAIR-01 | `wip/b25-home-door` `bcff138`, fast-forwarded into `wip/expansion20`, then `34e1041` | `bcff138` | none | See KNOWN_ISSUES KI-HOME-DOOR. | merged | none |
| **PAUSED:** flight findings investigation (read-only) | FR-REPAIR-01 point 6 | worktree `.claude/worktrees/fr-investigate` (clean); `wip/b25-fr-investigate` holds nothing | — | none | Findings recorded: KI-FR-CARTHITCH (loop, fix proposed, not made), KI-FR-WHEATSALE (market outcome), KI-FR-CONTRACTS (no-player artefact). Logs in the session scratchpad `fri/`. | report only | Awaits the owner. |
| Merged: make CI green | HAG-MEM-02, CI | `wip/b25-ci-green` `a5667ed`, merged into `wip/expansion20`, then `0d194c8` (two uid files) | `a5667ed` | none | `ci-out` excluded from the asset check; `refuge_test` compares timers within a microminute; `housing_test` clears trees for open ground; `tests.yml` timeout 210. | merged | Worktree retired 2026-11-02 (INTEGRATED, leftover files identical); branch kept. Read Tests 41509578455. |
| Merged and done | coin_sources leak fix (`8acbdea`, from `wip/b25-leak2` `57a7022`; INT renumbered to 676), Flight recorder system (`cad96c4`, from `wip/b25-flight-recorder` `8e59dfb`; long-sims `flight=true`; trial run 41464356721), Chapel economic purpose (`8b203c5`, from `wip/b25-chapel-purpose` `8ec9a85`; owner questions CHAPEL-GIVE-14-Q and the nine lending questions in CHAPEL_LENDING_PROPOSAL.md, docs/expansion20 on the Build 25 source), Chapel food spoilage and food alms (`35fbd48`, from `wip/b25-chapel-food` `fa75bd1`; owner question B25-CHAPEL-FOOD-Q), Firewood fixes and the affordability findings (`8654451`, from `wip/b25-firewood` `15c4d57`), LE-05 route risk (`0c122b6`, from `wip/b25-le05-risk` `ba2cc3e`; LE-07 gate 10 no longer waits on it), Economic investigation (`d6ab686`, from `wip/b25-econ-funnel` `86c0b80`; ECONOMIC_INVESTIGATION_2026-11-02.md in docs/expansion20 on the Build 25 source; owner questions B25-ECON-P1..P5), LE-07 gate review (`28d5280`, from `wip/b25-le07` `ddf2fdf`; status in LE07_GATE_STATUS.md, docs/expansion20 on the Build 25 source: gates 2, 3, 5, 7, 8 passed; 1, 4, 6, 9 need the final runs; 10 waits on the LE-05 remainder; 11 needs a device), B25-NINE-D1 and D8 skills and milestones (`625e362`, from `wip/b25-capability` `54a4850`), B25-NINE-D5..D7 materials, armour and clothing (`48acc91`, from `wip/b25-materials` `c1dfb02`), JUICE-J1 game juice J1 and J2 (`ba94edd`, from `wip/b25-juice` `4b72103`), B25-NINE-D4 witness reporting (`2c364d1`, from `wip/b25-report` `5bf548c`), B25-BIZ-OWN (B25-BIZ-D1..D5; `908a17e`, from `wip/b25-bizown` `9926ddf`), B25-NINE-D2 services and CON-03..CON-08 (`8d71c5e`, from `wip/b25-services` `1388f36`), B25-BUSINESS-IMPL and EMP-PERM-01 (`d0dc0d7`, from `wip/b25-business` `c60ac0e`), B25-AMBITION-IMPL, B25-EMPLOY-IMPL, LE-05/LE-07 remainder, P21-00..02, X20-CHAPEL-FIX, X20-TELL-GUARD | `wip/b25-ambition`, `wip/b25-employ`, `wip/b25-econ`, `wip/b25-civic`, `wip/x20-chapel`, `wip/x20-tell-guard` | merged into `wip/expansion20` | none | See the changelog. | merged | none |

All suspended worktrees are kept on disk. Their branches are pushed, so GitHub has everything committed. The resume order is in
"Next authorized actions" below.

## Current tests and results (Build 25 source)

All of these ran **locally** (Godot 4.7 headless), not in CI. Exact suites and counts are in `docs/DEVELOPMENT_CHANGELOG.md`.

| SHA | Level | Evidence |
|---|---|---|
| `3c7e45b` | TESTED | Option B: business_founding 66 (tenant standalone, no build onto the landlord's house, no home refused, player parity), business_ownership 165, business 160, conservation 8, wiki_test, all 0 failures; run_tests 3602 and start_test 523 steps, 0 failures. |
| `625e362` | TESTED | Merge tree identical to `wip/b25-capability` `54a4850`. run_tests 3602, start 523, experience 79, underground and regional_food suites, plus 20 suites on `4976137`, 0 failures. 30-day seed 1: 4 milestones, each announced once; no leaks. |
| `f8f9cac` | TESTED | Lead fixes: experience_test 79 (it had failed 1 since the services merge), services_d2 89, contracts 154, business_founding 61, business_ownership 165, conservation 8, all 0 failures. |
| `48acc91` | TESTED | Merge tree identical to `wip/b25-materials` `c1dfb02`. materials_b25 104, run_tests 3602, 20+ gear, combat, underground, settlement and save suites, 0 failures. 30-day seed 1 fingerprint changes (new materials), no errors or leaks. |
| `ba94edd` | TESTED | Merge tree identical to `wip/b25-juice` `4b72103`. juice 44, UI and net UI suites, multiplayer_c 340, run_tests 3601, 0 failures (`1a483de`). Presentation only: 10-day seed 1 fingerprint `0e5e945a` identical to `2c364d1`. |
| `2c364d1` | TESTED | Merge tree identical to `wip/b25-report` `5bf548c`. Worker evidence on `eab25e2`: judgment, justice, family, recorder and save suites, multiplayer_c 340, run_tests 3601, 0 failures. 30-day seed 1: 29 report choices, all chose to tell. |
| `908a17e` | TESTED | Merge tree identical to `wip/b25-bizown` `9926ddf`. Worker evidence on `b10eab3`: business_ownership 165 and 21 regression suites, run_tests 3601, 0 failures. Read-only `BIZ` line is fingerprint-neutral (10-day seed 1, `0e5e945a`). 90-day seed 1: leaks 0, **no workshop built**. Year-long run 41362329381 pending. |
| `8d71c5e` | TESTED | Merge tree identical to `1388f36`. Worker evidence: services_d2 89, contracts 154, multiplayer_c 340, farming 224, migration 109, run_tests 3601 and more (changelog). services_d2 89 and conservation 8 re-run on the merge. Contract window rows not yet looked at on screen. |
| `d0dc0d7` | TESTED | `business_founding` 58, `migration` 109, `save_continuity` 5, `save_transfer` 21, `run_tests` 3601, 0 failures; worker suites on `c60ac0e` in the changelog. 30-day seed 1 on `c60ac0e`: leaks 0, no villager founded a business (not yet seen in a live run) |
| `265ddc1` | TESTED | `skilled_employment` 54, `run_tests` 3601, 0 failures |
| `2c0a780` | TESTED | Save suites: `save_continuity` 5, `save_transfer` 21, `migration` 109, `le06_save` 21, `le07_gates` 25, `start_test` 523 |
| `63c0144` | TESTED | LE-05 and LE-07 suites, `net_econ_integrity` 126 |
| `ae8641d` | VALIDATED, CI | Year-long chapel runs: Actions 41279031310 and 41279051834 |
| `55c0881` | TESTED | Neutrality fingerprints identical to `ae8641d` |

**Not yet done on the integrated source:**
- a new 30-day baseline (the stored one is for `a3643c8`);
- full suites in CI (`tests.yml` runs only on staging pushes);
- network suites;
- year-long runs;
- the 13 LE-07 gates on the integrated candidate.

These are planned once, at the end.

## Known defects and risks

**The durable record is `docs/KNOWN_ISSUES.md` (HAG-MEM-02).** Where the list below differs, that file is newer: the firewood defects are fixed, unaffordable bids are an outcome, the coin_sources leak is fixed.

- **Pre-existing failure:** the `housing_test` loft check fails. It failed before the 2026-11-01 changes too. Not yet classified.
- **Suspected, not yet classified (X20-FIREWOOD):**
  - firewood collapse after day ~180 in normal runs (woodcutters fall from 6 to 1-2 while logs are held);
  - 0 of 30-56 manor-advanced axes delivered;
  - the manor wage raise never fires.
- **About 12,600 unaffordable market bids a year (X20-AFFORD).** Instrumented, not yet analysed.
- **Save limit:** movement in progress is not saved, so a loaded game is deterministic but not identical to an uninterrupted one.
- **Multiplayer:**
  - no net suite recorded on current code;
  - real-device and real-network checks not done.
- **Not a defect:** "leaked at exit" warnings in Godot test logs are long-standing noise.

## Outstanding owner decisions

The full list is `docs/requirements/views/DECISIONS.md`, with context in `docs/expansions/OWNER_DECISIONS_PENDING.md`. These touch
Build 25:

- Do approvals never placed in any build belong to Build 25? These are JOB-02, PIT-02, FSE-10 and PL2-015-BUYANIMALS. The CON items
  are now covered by B25-BUSINESS-D2 and B25-NINE-D2.
- Open owner-level items:
  - settlement capability knowledge (no supplier selection exists);
  - the tavern employment measure;
  - immigrants are offered only vacancies;
  - the succession floor.
- Packaging authorization for Build 25, once scope is complete.
- Kept open, not for Build 25: JUICE-JD2..JD5 and later-expansion questions.

## Next authorized actions (in order)

**Build 25 scope corrected (owner 2026-11-02, B25-SCOPE-REGION): the regional economy (REGION-NAV-01) is mandatory Build 25 scope.** `4b51c92` is the tested baseline; its campaigns (41536805310, 41536810831) run on as baseline evidence. Work: REGION-NAV-01 stages S1-S8 on `wip/region-nav`, one worker (the lead). Next: read it, then the owner's answers to B25-ECON-P1..P5 and the phone test (gate 11). Closure audit: `docs/release/build25_reconciliation/BUILD25_CLOSURE_2026-11-02.md`. Packaging waits on the owner decisions listed there (a year-long campaign, B25-ECON-P1..P5, LE-07 gate 11, reconciliation Q2). The items below are not picked up without the owner.

0. **Flight recorder repair** (FR-REPAIR-01, owner 2026-11-02, `docs/directives/2026-11-02_flight_recorder_investigation_repair.md`): KI-HOME-DOOR fix and evidence, then the cart_hitch, wheat-sale and contract-cancellation classification. **No full 365-day campaign** until the focused repairs and regression tests pass; then propose it with the exact fixed SHA and the reusable evidence.
1. Done: business founding, business hiring and permanent employment (`d0dc0d7`). Founding is not yet seen in a live run.
2. **Business ownership, paid employment and economic expansion** (B25-BIZ-OWN, decisions B25-BIZ-D1..D5, owner 2026-11-01,
   `docs/directives/2026-11-01_business_ownership_employment_final_decisions.md`). The owner answered the five open business
   questions; four of the conservative choices merged in `d0dc0d7` are to be replaced. **Merged at `908a17e`.** Spec: BUSINESS_OWNERSHIP.md in docs/expansion20 on the Build 25 source.
   Still to show: whether villagers found, buy, sell, hire and expand on their own over a year (run 41362329381). From branch `wip/b25-bizown`.
   Milestones, each pushed:
   1. architecture audit, reuse plan and the two-shop investigation;
   2. separate business finances and paid workshop employment;
   3. permanent employment across professions;
   4. buying, selling and ownership transfers, with home workshops kept separate from the home;
   5. expansion, career changes and abandoning unfinished construction;
   6. interface, wiki, targeted tests, longer simulations (on Actions) and integration.
3. **Suspended branches**, one at a time. Finish each, run targeted tests, then merge:

   The order may change if a dependency requires it.
4. **Farming yield by simulation** (FARM-YIELD-D1, B25-NINE-D3). Use Actions variants of `shared_wheat_yield`.
5. **Economy readiness:** run the 13 LE-07 gates on the integrated candidate, then switch the economy on by default
   (B25-LE-ACTIVATE-D1). Together with EMP-PERM-01 (steps 1-2), this closes X20-COMPLETE, the remaining Expansion 20 work (lead,
   in development).
6. **Validation once, at the end, on Actions:**
   - a new 30-day baseline;
   - full suites including network suites;
   - year-long runs (normal settings seeds 1 and 2, economy on seed 1);
   - the X20-ECON-MATURE report.
7. **Release-readiness report**, then packaging only on the owner's authorization.

## Restrictions in force

- Never merge to `main`. Never force-push staging.
- Do not alter Build 24.
- Do not answer owner decisions.
- Never print or replace the Android signing secrets.
- The package id stays `com.hotatticgames.mymedievallife.dev`.
- Never restart, cancel or duplicate a running simulation (SIM-02).
- A village may fail; the simulation may not (WDR-022).

## History links

| What | Where |
|---|---|
| Development history | `docs/DEVELOPMENT_CHANGELOG.md` |
| Previous handoffs | `docs/handoffs/archive/`. The latest is `CURRENT_DEVELOPMENT_STATE_to_2026-11-01.md`, which holds the historical 2026-10-31 Build 25-27 sequence. |
| Build 25 scope and audit | `docs/release/build25_reconciliation/` |
| Expansion status | `docs/expansions/README.md` |
