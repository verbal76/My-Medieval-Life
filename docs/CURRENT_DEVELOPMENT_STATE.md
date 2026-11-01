# Current development state (start here)

**This is the one current-state document.** Owner directives MEM-01 and DOC-CONT-01 make it the entry point.

- **Updated:** 2026-11-01.
- **Where the authoritative copy lives:** branch `wip/requirements-control`. The owner keeps that branch isolated, so copies of this
  file on `staging/my-medieval-life`, `wip/expansion20` and older branches are stale. Each of those copies carries a banner saying so.
- **What this file holds:** session state only.
  - Requirement and decision status lives in the register, `docs/requirements/requirements.json`, with generated views in
    `docs/requirements/views/`.
  - History lives in `docs/DEVELOPMENT_CHANGELOG.md`.
- **Recovery after lost context:** `docs/handoffs/CURRENT_SESSION_RECOVERY.md`.

## Position

| Item | Value |
|---|---|
| Current development build | **Build 25**, the consolidation build. It holds all approved expansion work and all approved recoverable abandoned-branch work (B25-SCOPE-D1, `docs/directives/2026-11-01_build25_scope_clarification.md`). |
| Integration branch (Build 25 source) | `wip/expansion20` |
| Development head | `908a17e` (business ownership, paid employment and expansion merged on top of services `8d71c5e`). See `docs/DEVELOPMENT_CHANGELOG.md` for the chain from `ad281dc`. |
| Latest verified SHA | `908a17e`: suites TESTED locally, listed below. No CI run, no 30-day baseline and no year-long run on this SHA. The last SHA with year-long CI evidence is `ae8641d` (chapel fix). The last SHA with a complete validated gate is `ad281dc` (30-day baseline). Its year-long runs failed on the gossip crash, which is now fixed. |
| Rollback point | `ad281dc` |
| Records branch | `wip/requirements-control`. It holds the register, directives and this file. The register is edited only here, with `tools/requirements_update.py` and then `tools/check_requirements.py --write`. It is not merged into staging or `wip/expansion20` without the owner's authorization. |
| `staging/my-medieval-life` | `baa6479` (2026-11-01; `aeaa012` plus the stale-copy banner). Behind on both code and records. Not where current work is. |
| Latest packaged build | Build 24: commit `4611d86`, run 40636966840, private three-platform draft. Frozen. There is no `build-24` git tag; the draft release is the record. Builds 22 and 23 are frozen. |
| Packaging and release | No Build 25 package exists. Packaging needs the owner's authorization. No public release. |
| Living Economy | Integrated but **off** by default. It switches on by default once the 13 LE-07 readiness gates pass on the integrated candidate, with no further approval (B25-LE-ACTIVATE-D1). |
| Operating mode | **Reduced-resource mode** (owner, 2026-11-01): one Claude coding worker at a time, no new agents, heavy computation on GitHub Actions (`long-sims.yml`), minimal reporting. It lasts until the owner restores normal priority. |
| GitHub Actions | **Running:** long-sims 41362329381 on `908a17e`, 365 days, seeds 1 and 2, checkpoints every 30 days. Dispatched 2026-11-01 23:29 UTC; expect about 1-1.5 hours. Never cancel or rerun it (SIM-02). Read the `BIZ`, `CHAPEL`, `ECON10` and day lines when it finishes. |

## Workers and branches (recovery records)

Every branch below holds real, unmerged work. None is disposable.

| Worker or workstream | Register | Branch / worktree | Latest pushed | Unpushed | State and tests | Merge readiness | Next safe step |
|---|---|---|---|---|---|---|---|
| **ACTIVE:** witness reporting | B25-NINE-D4 (X19-SWITCHES-D1) | `wip/b25-report`; worktree `.claude/worktrees/agent-a93f29147d5552724` | `f15faf8` | none at resume | Resumed 2026-11-01. `integration.report` is on. Remaining: wiki lines that still say every witness reports, suites, catching up with `908a17e`. | not ready | Finish, run the judgment suites, then the lead merges. Activation follows validation (Decision 4). |
| Suspended: game juice J1 and J2 | JUICE-J1 (B25-NINE-D9) | `wip/b25-juice`; worktree `.claude/worktrees/agent-*` | `efd0cd0` | none | Own test only. Missing: fingerprint neutrality, suites, INT entry, the Decision 8 notification routing note. API: `GameUI.personal(text, item, category, seconds)`; `World.note(text)`. | not ready | Finish the missing items, run targeted suites, merge. |
| Suspended: materials, armour, clothing | B25-NINE-D5..D7, ARMOR-CATALOG-D1 | `wip/b25-materials` | `041a67c` | none | Untested. Remaining: `resources.json` with `check_resources.py --write`, icons through the asset pipeline, wiki, tests. | not ready | Complete the data and tests, then merge. |
| Suspended: organic skills and capabilities | B25-NINE-D1, B25-NINE-D8 | `wip/b25-capability` | `f891a11` | none | Partly tested. Dependency: settlement capability knowledge needs supplier selection, which does not exist yet. | not ready | Finish, run targeted tests, merge. |
| Merged and done | B25-BIZ-OWN (B25-BIZ-D1..D5; `908a17e`, from `wip/b25-bizown` `9926ddf`), B25-NINE-D2 services and CON-03..CON-08 (`8d71c5e`, from `wip/b25-services` `1388f36`), B25-BUSINESS-IMPL and EMP-PERM-01 (`d0dc0d7`, from `wip/b25-business` `c60ac0e`), B25-AMBITION-IMPL, B25-EMPLOY-IMPL, LE-05/LE-07 remainder, P21-00..02, X20-CHAPEL-FIX, X20-TELL-GUARD | `wip/b25-ambition`, `wip/b25-employ`, `wip/b25-econ`, `wip/b25-civic`, `wip/x20-chapel`, `wip/x20-tell-guard` | merged into `wip/expansion20` | none | See the changelog. | merged | none |

All suspended worktrees are kept on disk. Their branches are pushed, so GitHub has everything committed. The resume order is in
"Next authorized actions" below.

## Current tests and results (Build 25 source)

All of these ran **locally** (Godot 4.7 headless), not in CI. Exact suites and counts are in `docs/DEVELOPMENT_CHANGELOG.md`.

| SHA | Level | Evidence |
|---|---|---|
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
   1. `wip/b25-report` (active)
   2. `wip/b25-juice`
   3. `wip/b25-materials`
   4. `wip/b25-capability`

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
