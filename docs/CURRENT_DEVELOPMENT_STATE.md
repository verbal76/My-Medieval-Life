# Current development state (start here)

**This is the one current-state document.** Owner directives MEM-01 and DOC-CONT-01 make it the entry point.

- **Updated:** 2026-11-01.
- **Snapshot last verified:** 2026-11-02 21:15 UTC by the lead, against wip/expansion20 `34e1041`, wip/requirements-control (this commit), Actions runs to 41509578455.
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
| Development head | `34e1041` (2026-11-02): KI-HOME-DOOR fix integrated (from `wip/b25-home-door` `bcff138`, fast-forward) and `home_ref_test` registered in CI; on `d73bd0a` (BRANCH-POL-01), `0d194c8`, `a5667ed` (CI-green), `9c56199`. Earlier chain in `docs/DEVELOPMENT_CHANGELOG.md`. |
| Latest verified SHA | `3c7e45b`: suites TESTED locally, listed below. No CI run, no 30-day baseline and no year-long run on this SHA. The last SHA with year-long CI evidence is `ae8641d` (chapel fix). The last SHA with a complete validated gate is `ad281dc` (30-day baseline). Its year-long runs failed on the gossip crash, which is now fixed. |
| Rollback point | `ad281dc` |
| Records branch | `wip/requirements-control`. It holds the register, directives and this file. The register is edited only here, with `tools/requirements_update.py` and then `tools/check_requirements.py --write`. It is not merged into staging or `wip/expansion20` without the owner's authorization. |
| `staging/my-medieval-life` | `baa6479` (2026-11-01). **Historical** (BRANCH-POL-01): the old records lineage. Its 447 commits not on `wip/expansion20` are records history, not unmerged code. Never merged into the integration branch. |
| Latest packaged build | Build 24: commit `4611d86`, run 40636966840, private three-platform draft. Frozen. There is no `build-24` git tag; the draft release is the record. Builds 22 and 23 are frozen. |
| Packaging and release | No Build 25 package exists. Packaging needs the owner's authorization. No public release. |
| Living Economy | Integrated but **off** by default. It switches on by default once the 13 LE-07 readiness gates pass on the integrated candidate, with no further approval (B25-LE-ACTIVATE-D1). |
| Operating mode | **STANDBY** (owner, 2026-11-02, MML-CONSERVE-01): MML is second priority behind Upwardly. At most one Claude worker; no parallel investigators, background sessions, scheduled follow-ups, new features or 365-day campaigns without the owner's approval. Nothing is being worked on. |
| GitHub Actions | **Running:** Tests [41509578455](https://github.com/verbal76/My-Medieval-Life/actions/runs/41509578455) on `0d194c8` (dispatched 19:24 UTC; not cancelled by the consolidation). **Finished:** flight campaign [41469410306](https://github.com/verbal76/My-Medieval-Life/actions/runs/41469410306) (`8acbdea`; seed 1 clean, seed 2 KI-HOME-DOOR); farming B1 41469335443 and B2 41469341029 (both food-secure; baseline 1.75, KI-01); long-sims 41458375116 (KI-REC-RUNNER); Tests 41482218360 (135/138, fixed by the CI-green merge). No long simulation is to start until FR-REPAIR-01's focused repairs pass. |

## Workers and branches (recovery records)

**File ownership (BRANCH-POL-01, 2026-11-02).** Merge order: KI-HOME-DOOR first, then farming Phase 2 (which merges the integration branch in before submitting).
- **Home-door:** `npc_brain.gd` (evening and home logic), `construction.gd` (home and resident handling), `world.gd` (`building_door` and the home-reference helpers), `home_ref_test.gd`.
- **Farming Phase 2:** `balance.json`, `farming.gd`, `population.gd`, `wiki.gd`, `wiki_farming.gd`, the farm tests, `resources.json` and its generated files, `FARMING_YIELD_CALIBRATION.md`, and the farming code in `world.gd`.
- **Shared:** `docs/DECISIONS.md` and `SYSTEM_INTERACTION_MANIFEST.md`; each worker edits only its own entries.
- **The investigation** owns nothing and commits nothing.

Every branch below holds real, unmerged work. None is disposable.

| Worker or workstream | Register | Branch / worktree | Latest pushed | Unpushed | State and tests | Merge readiness | Next safe step |
|---|---|---|---|---|---|---|---|
| **PAUSED:** farming yield Phase 2 | B25-NINE-D3, FARM-YIELD-D1 | `wip/b25-farm-phase2` `710fce9` (WIP, pushed); worktree `.claude/worktrees/farm-phase2` | `710fce9` | none | Yield 1.75 and both switches set; old-save seed corn (`World.start_shared_farming`, `farm_shared_save_test`); stale tests and wiki updated; 25 suites 0 failures; smoke `166eaf82`. | not ready | On resumption: commit the test's uid file, merge `wip/expansion20` (overlaps home-door in `world.gd`, DECISIONS, manifest), rerun the targeted suites, merge. |
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

**B25-CLOSE-01 (owner 2026-11-02): complete Build 25 before packaging, one worker (the lead).** In progress on `wip/b25-farm-phase2`: farming Phase 2, the cart-hitch fix and the seed-corn ledger fix, then one frozen SHA and targeted validation. Closure audit: `docs/release/build25_reconciliation/BUILD25_CLOSURE_2026-11-02.md`. Packaging waits on the owner decisions listed there (a year-long campaign, B25-ECON-P1..P5, LE-07 gate 11, reconciliation Q2). The items below are not picked up without the owner.

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
