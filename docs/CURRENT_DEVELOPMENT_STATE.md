# Current development state (start here)

**This is the one current-state document.** Owner directives MEM-01 and DOC-CONT-01 make it the entry point.

- **Updated:** 2026-11-09 13:35 EST (documentation agent, HAG-FORENSICS-01 recovery: top pointer, stamp, worker inventory).
  The previous stamp ("Updated 2026-11-06 19:00 EST"; "Snapshot last verified 2026-11-07 03:30 UTC ... `fe7d8f8`") had stayed
  unchanged through the 2026-11-08/09 entries below, although those entries were current. It is corrected here. The old wording
  is in git history.
- **Snapshot last verified:** 2026-11-09 21:20 UTC (16:20 EST) by the lead, against wip/b25r2-rev2 `e44d6b8`,
  wip/requirements-control (this commit), docs/build25-audit-register `67c667d`, Actions runs to 42664730920 (completed; no
  run in progress).
  - **Convention:** whoever checks this file against the live GitHub state writes this line as
    `YYYY-MM-DD HH:MM UTC by <session or agent>, against <development line, now wip/b25r2-rev2> <sha>, wip/requirements-control
    <sha>, Actions runs to <newest run id>`. (Until 2026-11-09 this read `wip/expansion20`, which stopped being the development
    line on 2026-11-03.)
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

> **Work preservation, 2026-11-09 17:10 EST (HAG-PRESERVE-01):** all uncommitted work in 29 worktrees snapshotted to GitHub
> (`wip/backup-20261109/*`, 58 branches) and verified against GitHub's copy (288 files, 0 mismatches). Free disk about 526 MB.
> Record: `docs/audits/2026-11-09_WORK_PRESERVATION_EVENT.md`. Before disk-heavy work, check `df -h /`.

## CURRENT BUILD 25 STATE: read this first (pointer, 2026-11-09 18:34 UTC)

Written by the documentation agent (HAG-FORENSICS-01) from the live GitHub state. The dated sections below hold the detail,
newest first, under "MONDAY RECOVERY POINT". Sections further down ("Build 25 Revision 1", "Overnight autonomous development",
"Position", "Workers and branches", "Current tests and results", "Known defects") are **history**. They describe `wip/expansion20`
and `wip/b25r1`, which are no longer the development line.

| Item | Value |
|---|---|
| Build | Build 25, Revision 2 ("Play Test Build One"); the package label is to be "0.1.34 Rev 2 — Playtest 1" (B25R2-VER-01) |
| **Development line (code)** | **`wip/b25r2-rev2` at `167b235`** (2026-11-10 05:48 UTC / 00:48 EST: KI-09 fix merged on `72729e5`, Tests 42758089184 green on that SHA). Next: MP-03 + TRD-05 merged on top as `93bb304` (`wip/b25-nosim-on-dev`), Tests dispatched 05:49 UTC; batch 3 (`wip/b25-audit-sim3`) in validation |
| Records branch | `wip/requirements-control`: register, directives, this file, changelog, known issues, decision records. Lead only |
| Audit register | branch docs/build25-audit-register, commit `257475c`, file docs/audits/2026-11-08_build25_master_audit_register.md on that branch; tracking issue #4 |
| Running Actions | None. Last: MP-05 recorded campaign [42664730920](https://github.com/verbal76/My-Medieval-Life/actions/runs/42664730920) on `242ca83`, completed 21:13 UTC: seed 1 365/365 0 CRITICAL 17 HIGH 46 MEDIUM 0 confirmed; seed 2 365/365 0/63/42 0 confirmed (identical to `c9da5db`) |
| Pending integration | None. Next authorized work: MP-05 device and security checks (two devices, modified client, reconnect, menus); EMP-03 fix (KI-15); MP-07, REG-04, REG-05 implementation; REG-08 investigation. No release without the owner (REL-OWNER-01) |
| Merged on the development line since `fe7d8f8` | `f0a854c` Batch A (PRs #5-#15 + BRUSHOFF); `229f76e` LIFE-03/04; `96b071c` PROP-06; `53a56d3` JUS-04/REG-07; `c9da5db` overnight backlog + PROP-03 test; `242ca83` MP-05 (PR #19 + two cart fixes). Evidence: `docs/DEVELOPMENT_CHANGELOG.md` (2026-11-08/09), `docs/decisions/B25-*` |
| Accepted simulation baseline | `df67e8e` (unchanged). Gate red of the baseline-difference kind is expected; the generation 8 candidate waits on the owner (TEST-AUDIT-Q2) |
| Packages and releases | The owner's provisional Windows package (artifact 13542782040, `1f2ff4f`, expires 2026-12-06). `build-34` (public, 2026-11-06, `a9e9f6e`). `build-25` draft (`a459186` files). No Play Test Build One draft yet (B25R2-DRAFT-01 conditions). No Steam upload |
| Approved, not implemented | MP-07 (privacy), REG-04 (physical couriers), REG-05 (physical migration); ChatGPT is to write PRs and Claude integrates. Open: SAV-04 (owner decision), REG-08 (investigation), the other static audit records |
| Owner decisions pending | TEST-AUDIT-Q2 (baseline); B25R2-DRAFT-01 conditions; the BRANCH-POL-01 text versus the actual development line |
| History recovery | HAG-FORENSICS-01: coverage register `docs/audits/2026-11-09_HISTORICAL_COVERAGE_REGISTER.md`; recovered owner messages `docs/directives/2026-11-0*_recovered_owner_messages.md`; the independent recovery test is the lead's |

### Worker inventory (directive HAG-FORENSICS-01, section 10)

| Task | Responsible | Branch | Last pushed SHA | Depends on | Status | Next action |
|---|---|---|---|---|---|---|
| Build 25 development, integration and merges | Lead (Claude session `754052d8`) | `wip/b25r2-rev2`; task branches `wip/b25-*` | `242ca83` | not applicable | active | Next authorized work in the pending-integration row |
| HAG-AUTH-01 decision-authority safeguard (lifecycle, supersession links, checks, retroactive audit) | Lead | `wip/requirements-control` | (this branch) | not applicable | in development (started 2026-11-09 13:45 EST) | Checker + view + tests, then the retroactive chain audit |
| EMP-03 hiring-competition seekers (KI-15 case 1) | Lead | `wip/b25-emp03` | `00e47a6` | Tests 42705032193 attempt 2 green (attempt 1: KI-12 only); gate 42705036907 33 blocking, baseline-difference only, determinism identical; recorded campaign 42705042231 running | in validation | Merge into `wip/b25r2-rev2` when CI, gate and campaign are clean |
| MP-05 forged-client security tests | Worker agent (PAR-AGENTS-01), worktree `audit-int` | `wip/b25-mp05-forge` | `448fc0b` | full Tests 42713486147 green; mp05_forged_client_test 53/0 | merged into `wip/b25r2-rev2` 2026-11-09 23:30 UTC | Remaining MP-05 checks: real two devices, reconnect, menus; container verbs (`container_store`, `container_pick`, `player_take`) could also require named records |
| REG-08 courier stranding investigation | Read-only investigator agent (PAR-AGENTS-01) | none | not applicable | code reading | done 2026-11-09 | Owner policy questions B25-AUD-REG-08; record `docs/decisions/REG-08-INVESTIGATION-2026-11-09.md` |
| Audit fixes without a simulation change: INV-01 (census counts stashes), BIZ-08 (hands after load), TRD-01 (guest stall settle), SAV-03 counter part (serving rebuilt on load) | Lead | `wip/b25-audit-fixes` | `e44d6b8` (fixes + merge of `448fc0b` + KI-12 fix) | failing-first tests: inv01 6/0 (2 before), biz08 5/0 (2), trd01 8/0 (5 + script errors), sav03 6/0 (2); related suites 0 failures incl. world_test 339/0; full Tests dispatched on `e44d6b8` | in validation | Fast-forward `wip/b25r2-rev2` to `e44d6b8` when green (no campaign: no simulation change) |
| SAV-05 save tests at the game's precision | Lead | `wip/b25-sav05` | `54794d9` | save_continuity_test 1 failure (KI-17) | blocked on KI-17 | Do not merge until saves reload exactly |
| KI-12 net_fault reconnect race | Worker agent (PAR-AGENTS-01), worktree `audit-int` (done) | `wip/b25-ki12-reconnect` | `dc049d9` | reproduced under load; fix 55/0 x4 under load | done; merged into `wip/b25-audit-fixes` `e44d6b8` | Merges with the audit fixes when CI is green |
| Audit fixes that change the simulation, batch 1: EMP-01, BIZ-05, BIZ-01/02, LIFE-02, INV-06 | Worker agent (PAR-AGENTS-01), worktree `audit-int` (done) | `wip/b25-audit-sim1` | `916db07` | failing-first: emp01 2->9/9, biz05 2->9/9, biz01 9->47/47, life02 6->14/14, wear_transfer 3->36/36; related suites 0 failures | done, awaiting the batch campaign | Combine with sim2 on the development line; strict CI, gate, one recorded campaign; then merge |
| Audit fixes that change the simulation, batch 2: REG-02 (journey part), NPC-02, JUS-02 | Lead | `wip/b25-audit-sim2` | `1497a5c` | failing-first: reg02 3->5/5, npc02 3->8/8, jus02 3->8/8; related suites 0 failures | done, in the simulation batch (REG-06, NPC-03 moved to batch 3) | As batch 1 |
| Simulation batch: EMP-03 + sim1 + sim2 on `e44d6b8` | Lead | `wip/b25-sim-batch` | `72729e5` (`acc24b2` + CI-file fix: shard number through env, the run block had passed GitHub's 21000-character expression limit) | EMP-03 campaign 42705042231 on `00e47a6` clean (0 CRITICAL, 17/46 and 63/42, 0 confirmed); batch: Tests 42734267343 on `72729e5` green (attempt 2; attempt 1 failed only `demo_test` exit -6, KI-09); gate 42734190370 33 blocking, all baseline-difference, determinism identical; recorded campaign 42734194963 on `acc24b2` (code identical): seed 1 365/365, 0 CRITICAL, HIGH 39, MEDIUM 50, 0 confirmed (ref 17/46); seed 2 365/365, 0 CRITICAL, HIGH 63, MEDIUM 42, 0 confirmed (ref 63/42) | merged: `wip/b25r2-rev2` fast-forwarded to `72729e5` 2026-11-10 04:48 UTC. Seed 1's HIGH rose 17 -> 39, mostly food-buying refusals on days 239-243 (a shortage episode, an outcome under WDR-022, not an invariant break); cause not yet traced to a specific fix: next investigation | | Fast-forward `wip/b25r2-rev2` when all are clean |
| Audit fixes that change the simulation, batch 3: REG-06 (live resident folded before their household changes), NPC-03 (manor hand taking a field counted and recorded; worked-out miner post kept on purpose) | Lead | `wip/b25-audit-sim3` (base `72729e5`) | `ea3c72b` (+ SAV-03 other maps `89a3b06`: sav03 reservations 4 -> 6/0; save, chapel, farm_plots, business, stalls suites 0 failures) | failing-first: reg06 5->15/0 (treasury took a fostered child's 5 coins, 320->325), npc03 2->4/0; hamlet, regions, migration, settlement_life, settlement_folk, identity, reg02, party, settle_review, courier_live, recorder, b25_recorder, emp01, emp03: 0 failures | in validation (with B25-SELFTRADE-VAL-01: extended test `fc16aa4`, 4 failures before the fix, 11/0 after): head `b57261f` (adds the self-trade payer fix found in the batch campaign: a seller was made payer for their own goods, 1262 refused retries a day; self_trade_payer_test 1 -> 3/0). Dispatched 2026-11-10 05:09 UTC: gate 42760288204, recorded campaign 42760291468 (seeds 1,2, 365 days), Tests 42760294917 | Merge onto the development line when all are clean (KI-09 does not change simulation output, so this evidence stands after it) |
| MP-03 host checks on stores a guest names | Worker agent (PAR-AGENTS-01), own worktree (done) | `wip/b25-mp03-store-auth` (base `72729e5`) | `0acded4` | mp03_forged_store_test 15 failures -> 35/0; mp05 forged 53, mp05 share 24, mp04 6, mp01 11, net_econ_integrity 126, net_interact 68, net_batch_b 45, net_c 43, net_g1 45, net_family 22: 0 failures; lead reviewed the diff (+15 lines in `NetActions._dec_inv`) | done | Merge with TRD-05 (`wip/b25-audit-nosim2`) after the KI-09 merge is green; strict CI on the merge head. Owner question: may guests name a public table as a store (none does today)? |
| B25-MP03-TABLES-D1 public tables for guests | Worker agent (PAR-AGENTS-01), worktree `agent-a1e875ac6410d6dda` (done) | `wip/b25-mp03-public-tables` (base `0acded4`) | `4b83422` | mp03_public_tables_test 4 failures -> 67/0 (allowed: public table in reach, away and back; refused: tavern, house, kept, parcel, out of reach, missing, crate, pack/pantry/granary, indirect route); mp03 forged 35, mp05 53/24, mp04 6, mp01 11, net_econ_integrity 126, net_interact 68, net_c 43, net_batch_b 45, net_g1 45, net_family 22, table_preview 17, chests 72, furniture 49: 0 failures; lead reviewed | done | Merge after `93bb304` is green, CI on the merge head. Owner questions: are tavern tables public (none of the 15 shipped tables is public under the rule)? a table in the guest's own house? a tavern table with no keeper left? |
| B25-MP03-OWNERSHIP-D1 property rules (owners' crates and home tables, tavern private, keeper death, host/guest parity) | Worker agent (PAR-AGENTS-01), same worktree | `wip/b25-mp03-public-tables` | `e3be9ef` (on `4b83422`) | mp03_household_tables_test 6 failures -> 66/0; 17 related suites incl. world_test 339 and start_test 523 steps: 0 failures; lead reviewed. Rule: a guest's container store is decided by `Chests.info` read as the guest (own, or shared under MP-INTERACT-01), within reach of the host's record of the guest; everything else refused; all 15 tavern tables private, also after both keepers die | in review: lead asked the worker to check that a shared crate cannot be used to spend items the sharing tier forbids (MP-05 tiers) | Findings: (1) the host's `is_host` pass in `_dec_inv` is unused by the host's own UI (it calls verbs directly), no single-player refusal to match, left; (2) a resident household member may use the home food table but not its crates without a sharing agreement (`Chests.info` treats residence as nothing for storage): owner question; (3) no reach check on a home food table recipe start (`player_craft_begin`), same for host in single player: parity gap, reported, not changed; (4) a dead keeper's table dish with no keeper alive stays private with no owner and no estate rule returns it: documented gap, no new system |
| B25-INV02-SPOIL-D1 spoilage investigation and proposal | Worker agent (PAR-AGENTS-01), worktree `audit-int` (done) | `wip/b25-inv02-proposal` (base `167b235`) | `906f1a8` | proposal INV02_SPOILAGE_PROPOSAL.md in docs/design on that branch; prototype behind a new off-by-default switch (`economy_sim.gd --spoil-storage`): flag off identical to the base (seed 1, 60 days, same final fingerprint); flag on ledgers exact, 0 starvation either way, village food 9.33 -> 10.04 days, granary wheat 224 -> 298; inv02_storage_proto_test 7/0, decay_test 37/0 | proposal delivered: awaiting the owner's seven decisions; NOT enabled, not in any campaign | Owner decisions 1-7 (storage classes, settlements, couriers, base rates, offline guest, eat perishable first, preserving), then BASELINE-AUTH-01 and a 4-seed 365-day comparison. Left on disk by the worker: uncommitted probe `audit-int/game/tests/_inv02_probe.gd`, scratch copy `scratchpad/inv02/base` (116 MB, a copy of the branch base) |
| MP-06 away guest at the gateway | Lead | none | none | a gateway-wide away refusal broke `net_c_test` (a rejoining guest is away by design until its first move, MP-D1; its case was lost); withdrawn, test kept in the lead's scratchpad | OPEN | Per-verb rule needed; low severity |
| KI-09 `demo_test` exit crash (double free) | Worker agent (PAR-AGENTS-01), worktree `audit-int` (done) | `wip/b25-ki09-demo-exit` | `e276c9f` (base `e44d6b8`) | root cause: `RegionGeo._cache` written by two threads (main + `AerialMap.start_sites` worker, fresh cache only); Mutex fix; locally under load 1/20 crashed before, 0/20 after; demo 35/0 x20, start 523/0, aerial 79/0, region_geography 992/0 | MERGED: development line at `167b235` 2026-11-10 05:48 UTC (Tests 42758089184 green, demo_test 35/0) | Watch demo_test in later runs |
| MP-05 integration | Lead | `wip/b25-mp05-on-dev` | `242ca83` | campaign 42664730920 clean | merged into `wip/b25r2-rev2` 2026-11-09 21:18 UTC | Device and security checks outstanding (KI-13) |
| Historical recovery (HAG-FORENSICS-01) | Documentation agent (subagent of the lead) | branch docs/history-recovery-2026-11 (local; the lead integrates each checkpoint into `wip/requirements-control`, since the pre-push hook refuses register copies on other branches) | integrated `8d16416` | lead integration | active | Finish changelog, state, recovery and known-issues repairs; lead runs the register commands and the independent recovery test |
| Audit corrections and approved features (MP-07, REG-04, REG-05, further audit items) | ChatGPT, through the owner's GitHub account | `audit/*`, `feature/*` (new PRs) | not applicable | not applicable | none open except PR #19 | The lead retrieves and integrates new PRs as they appear (owner directive 2026-11-08) |

**Frozen or historical branches.** Do not develop on these:
- `wip/b25r2-playtest` `1f2ff4f`: the provisional package's source.
- `wip/b25r1` `20e579e`: F2.
- `wip/expansion20` `a459186`: the Build 25 draft.
- `staging/my-medieval-life` `a919963`: historical (BRANCH-POL-01).
- `main` `de76782`: owner only.
- Superseded integration and task branches: `wip/b25-audit-integration` `f0a854c`, `wip/b25-features-integration` `494af9a`,
  `wip/b25-prop06-integration` `a7071aa`, `wip/b25-prop06-merge`, `wip/b25-next-batch` `4f1b3c8`, `wip/b25-next-merge`,
  `wip/b25-backlog` `f67afdb`, `wip/b25-backlog-merge` `c9da5db`, `wip/b25-prop03` `b727954`, `wip/b25-mp05-integration`
  `be307f8`. All are contained in `c9da5db` except the MP-05 one.
- Audit and feature PR branches `audit/*-20261108` and `feature/*-20261108`, kept per BRANCH-POL-01.
- `wip/test-audit` `7971720`: its `door_exit_test` is not yet in a candidate.


## MONDAY RECOVERY POINT (owner, 2026-11-06 late night; `docs/directives/2026-11-06_finish_tests_save_stop.md`)

*(Note 2026-11-09, HAG-FORENSICS-01 recovery test: since 2026-11-09 the first bullets under this heading are the dated Build 25 merge log, newest first. The current state is the pointer section above; the 2026-11-06 hold described here ended with the owner's 2026-11-09 directives.)*

> **Note (2026-11-09, documentation agent):** the hold described in the next paragraph ended when the owner authorized work on 2026-11-08
> (the audit directives, recovered in `docs/directives/2026-11-08_recovered_owner_messages.md`). The bullets from "Independent audit open
> items" on are current, newest at their top-dated entries.

**All Claude development is stopped until the owner authorizes work on Monday.** Saved 2026-11-07 03:30 UTC (2026-11-06 10:30 pm EST).

- **Branches and pushed SHAs:** candidate `wip/b25r2-playtest` `1f2ff4f` (unchanged; its package is the owner's provisional
  playtest build); owner's playtest fixes `wip/b25r2-rev2` `fe7d8f8`; records `wip/requirements-control` (this commit); audit
  `wip/test-audit` `7971720`. No GitHub Actions workflow is running (checked 03:25 UTC: none in progress).
- **Drawing suites (stutter fix), all 14 on `fe7d8f8`, local:** 1,885 checks, 0 failures, 1 script error (start_test: the latent
  `Dialogue.brush_off` empty-plan defect, B25R2-BRUSHOFF, not caused by tonight's changes, not repaired). Table in
  `docs/release/B25R2_COMPLETION_CHECKLIST.md`.
- **Stutter fix (B25R2-STUTTER, `ed221df` + `fe7d8f8`):** cause found and fixed (tiles made at the start); the walk to Wendholt went
  from 37 frames over 50 ms to 4, 0 tiles made in play; `tile_premake_test` 4/0, fails on the old code. Remaining: one frame of about
  150 ms at the village's hourly work, the known first-frame and 17:00 spikes (about 230 ms); headless only, a real PC unmeasured.
- **365-day simulations:** `1f2ff4f` run 42297637074 clean (both seeds 365/365, 0 CRITICAL, 0 confirmed; seed 1's HIGH warnings
  48 against 20 on `832f711`, an open, uninvestigated finding); `832f711` run 42274347279 finished (its homestead water defect fixed).
- **Generation 8 baseline:** candidate `docs/release/sim_baseline_candidate_gen8.json` (from gate 42297641550 on `1f2ff4f`), comparison
  in `docs/release/SIM_BASELINE_DIFFERENCES_B25R2.md`: every difference attributed, leaks 0, determinism identical. **Not accepted;
  the owner decides.** `sim_baseline.json` unchanged.
- **Unresolved:** B25R2-BRUSHOFF (above); seed 1's HIGH warnings; the 8 open coverage gaps (audit G1, G3, G4, G6, G7, G8, G9, G10's
  B7-008); the four playtest fixes and the stutter fix tested locally only (not CI); `door_exit_test` not yet in a candidate; the
  invite code length (owner's choice of option, nothing started); real controller and Windows PC checks (owner).
- **Package and release:** artifact 13542782040 (`1f2ff4f`, 0.1.34, Windows) for the owner's personal testing only (B25R2-PKG-01),
  without the playtest fixes. No release published or drafted. Private draft authorized only after the conditions of B25R2-DRAFT-01.
- **Independent audit open items (owner, 2026-11-08):** `docs/audits/2026-11-08_INDEPENDENT_AUDIT_OPEN_ITEMS_v14.md`, verbatim as the
  owner supplied it. 13 static-only reports (Audits 001-012, 009B) on `wip/b25r2-rev2` `fe7d8f8` (001 on `wip/expansion20`
  `a459186`): 69 tracked records (EMP 6, BIZ 8, TRD 5, INV 6, SAV 6, NPC 5, LIFE 5, REG 8, JUS 4, MP 7, PROP 6, REQ 3), **zero
  runtime-confirmed**; Audits 009/009B, 011, 012 partial. Owner: work on it when credits reset; paid audits stopped. Per its
  protocol: reproduce each on the exact SHA with an isolated test before any fix; owner decisions first for BIZ-03/04, INV-05,
  SAV-04, LIFE-03/04/05, REG-04/05/07, JUS-04, MP-05, PROP-06; never mark closed without a test run SHA. Its verification
  buckets, highest value first: multiplayer authority and guest shops (MP-01-05, PROP-01/02/05); person exit cleanup (LIFE-01/02,
  REG-02/03, JUS-01/02/03); lease/site recovery (PROP-03); save/load continuity (EMP-02, SAV-01/03, REG-01); ledger completeness
  and courier terminal states (INV-01/04, REG-03/08). B25R2-BRUSHOFF (found by start_test) is not in it: track it alongside.
- **Audit register on GitHub (2026-11-08):** master copy https://github.com/verbal76/My-Medieval-Life/blob/docs/build25-audit-register/docs/audits/2026-11-08_build25_master_audit_register.md
  (branch docs/build25-audit-register, commit e75ee5c); tracking issue https://github.com/verbal76/My-Medieval-Life/issues/4 (with the nine handoff rules).
- **MP-04 (forged free cart): REPRODUCED and CORRECTED, not merged.** Draft PR https://github.com/verbal76/My-Medieval-Life/pull/5
  (by ChatGPT via GitHub), branch `audit/mp04-cart-gateway-20261108` head `325dcad`, base `wip/b25r2-rev2` `fe7d8f8`, 4 files, +94/-1.
  Red: focused Godot run 42459686569 on the original code, 4 of 6 passed, 2 failed. Green: run 42459774174 at `32cab1d`, 6/0.
  Fix: `carts.place` taken out of `NetActions.VERBS`; `player_set_down_cart` stays. New test `mp04_cart_gateway_test.gd` (in
  tests.yml); evidence file 2026-11-08_MP04_CART_GATEWAY_VERIFICATION.md (on the PR branch). **Remaining:** the existing multiplayer suites
  and the full strict suite on the integration commit, then merge. Keep the branch and draft PR as they are until integration.
  It has to be merged into `wip/b25r2-rev2` along with the playtest fixes before the next package. Its Godot runs printed
  resources-in-use warnings at exit (not investigated). MP-03/05, INV-03, PROP-01/02/05 remain open and separate.
- **ChatGPT owner-authorized low-cost GitHub corrections (2026-11-08; after original audit handoff):** Four more audit issues have **runtime reproduction (red) and narrowly scoped correction (green) on independent draft PR branches**. This supersedes the historical "zero runtime-confirmed" phrase **for these four issues only**; the original v14 register remains unchanged as the snapshot of the 13 static audit reports. No merge, package, baseline promotion, or broad CI run has occurred for these fixes.
  - **PROP-01, foreign building-site cancellation** — draft [PR #6](https://github.com/verbal76/My-Medieval-Life/pull/6); red [42461697475](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461697475), 7 checks/5 failures; green [42461831319](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461831319), 7/0. Host's network gateway now verifies that the site belongs to the requesting player and refunds go only to that player's pack. Fix SHA `cf744a11`.
  - **PROP-05, forged NPC shop sale at arbitrary price** — draft [PR #7](https://github.com/verbal76/My-Medieval-Life/pull/7); red [42461609614](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461609614), 8/5; green [42461726200](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461726200), 8/0. Direct internal `business.sell` no longer guest-whitelisted; ordinary host customer sales continue. Fix SHA `c5e2db91`.
  - **PROP-02, foreign building fittings/stock removal** — draft [PR #8](https://github.com/verbal76/My-Medieval-Life/pull/8); red [42461880196](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461880196), 13/5; green [42461995223](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461995223), 13/0. The existing room-holder check now runs before fitting removal, shop closure or material refund. Fix SHA `ee3727ee`.
  - **JUS-03, justice cases surviving old-age death into the heir** — draft [PR #9](https://github.com/verbal76/My-Medieval-Life/pull/9); red [42462198471](https://github.com/verbal76/My-Medieval-Life/actions/runs/42462198471), 9/5; green [42462279977](https://github.com/verbal76/My-Medieval-Life/actions/runs/42462279977), 9/0. Old-age host and guest death now calls the existing case-closure hook. Fix SHA `6ab511f4`.
  - **With prior MP-04 draft PR #5:** **five** distinct audit concerns have now been reproduced and corrected on **unmerged branches** (MP-04 plus four above). Each PR includes focused tests registered in `.github/workflows/tests.yml`, evidence in `docs/audits/` and red/green exact-SHA Actions. The temporary single-runner workflows were deleted from the final PR diffs; 8 new one-runner jobs ran for the four newer fixes. **No Claude Console usage and no 12-runner suite were required for these new reproductions.** Full integration, combined multiplayer checks, simulation/determinism gates, independent owner review and merge are still outstanding. These items are **not closed**. The three network authority PRs (#5/#6/#7) affect `net_actions.gd`; consolidate carefully to avoid dropping changes. Do not silently merge or publish them.
- **Next batch (after the 12 merge), owner directive 2026-11-08 "continuous engineering":** PR #20 JUS-04 (head `fbc0384`,
  world.gd witness `relations.harmed(..., false)`; red 42520518399 6/1, green 42520403018 6/0) and PR #21 REG-07 (head `8ca63ed`,
  intel stale 4 / forget 8 days, envoy refresh 4, reeve's book expires old records; intel_test red 20/5 in 42520518399, green
  42520222693 20/0). Both based on `fe7d8f8`. At integration: drop their temporary focused workflows (audit-jus04-focused.yml,
  audit-reg07-focused.yml), add a floor for jus04_witness_knowledge_test and raise intel_test's floor to its new count; REG-07
  changes simulated trade, so attribute its gate differences (no baseline change without the owner).
- **Approved but NOT implemented (Issue #4, owner decisions 2026-11-08):** MP-07 (no private records in network snapshots, saves
  sent to guests or sync), REG-04 (couriers travel physically), REG-05 (households migrate physically). ChatGPT implements them;
  Claude integrates the tested PRs. REG-04 and REG-05 must share the one journey system. Not done; not to be reported as done.
- **Features CI:** the strict suite started on `46d934c` (42517545415) was cancelled by the branch's concurrency group when
  f0a854c's run began on the same branch name; it is re-run on `wip/b25-features-integration` when the features are next worked.
- **BATCH A MERGED 2026-11-08 23:37 UTC: `wip/b25r2-rev2` `fe7d8f8` -> `f0a854c` (fast-forward, no force).** The 11 audit
  corrections (PRs #5-#15: MP-04, PROP-01, PROP-05, PROP-02, PROP-04, JUS-03, JUS-01, LIFE-01, SAV-01, INV-03, MP-01) and
  B25R2-BRUSHOFF. Evidence on the tested SHA: strict Tests 42519022430 on `f0a854c` passed (0 failed suites, floors met); 365-day
  campaign 42515726815 on `0d252b4` (code identical but for the player-only brush-off guard): seed 1 365/365, 0 CRITICAL, 48 HIGH,
  65 MEDIUM, 0 confirmed defects; seed 2 365/365, 0 CRITICAL, 99 HIGH, 45 MEDIUM, 0 confirmed (reference 1f2ff4f: 0/48 and 0/99);
  gate 42509523836: 32 blocking findings, all baseline-only (df67e8e), identical to the development branch's; the baseline is not
  replaced (owner's decision). PRs #5-#15 closed naming `f0a854c`.
- **2026-11-09 21:18 UTC: MP-05 MERGED into `wip/b25r2-rev2` at `242ca83`** (fast-forward from `c9da5db`; `242ca83` =
  `c9da5db` + PR #19's diff + cart fixes `2e74066` (revoked partner lets go of a pulled cart) and `242ca83` (villagers' carts
  park again)). Evidence: full Tests 42636628469 on `242ca83` passed; recorded campaign 42664730920 on `242ca83`: seed 1 365/365
  0 CRITICAL 17 HIGH 46 MEDIUM 0 confirmed, seed 2 365/365 0/63/42 0 confirmed, identical to `c9da5db`. Not yet done: real
  two-device host/guest, modified-client forging, reconnect, UI walk (KI-13). No release (REL-OWNER-01).
- **2026-11-09 17:30 UTC: OVERNIGHT BACKLOG + PROP-03 TEST MERGED into `wip/b25r2-rev2` at `c9da5db`** (fast-forward from
  `53a56d3`; `c9da5db` = `53a56d3` + `wip/b25-backlog` `f67afdb` (LIFE-05, BIZ-03, BIZ-04, TRD-02, INV-04, INV-05, SAV-02;
  EMP-03 no change) + `wip/b25-prop03` `b727954`). Evidence: strict Tests 42607051457 attempt 2 passed (attempt 1:
  net_fault_test and net_mp4_test failed on CI timing; both pass locally on `c9da5db`, 54/0 and 148/0; the merge touches no
  net code, and SAV-02's new save keys are not net-synced sections); gate 42607055494 33 blocking, all baseline-difference kind,
  determinism identical; recorded campaign 42627103286 (flight, record): seed 1 365/365 0 CRITICAL 17 HIGH 46 MEDIUM 0
  confirmed, seed 2 365/365 0/63/42 0 confirmed, no FATAL. Development head: `c9da5db`. Next: MP-05 (`wip/b25-mp05-on-dev`
  `242ca83`, full CI 42636628469 green) under its own recorded campaign (it changes cart pulling and parking), then merge.
- **2026-11-09 11:05 UTC: JUS-04 + REG-07 MERGED into `wip/b25r2-rev2` at `53a56d3`** (fast-forward from `96b071c`; merge of
  `96b071c` and `4f1b3c8`; strict Tests 42597744977 on `53a56d3` passed; recorded campaign 42570299554 on `4f1b3c8`: seed 1
  365/365 0 CRITICAL 48 HIGH 65 MEDIUM 0 confirmed, seed 2 365/365 0/94/36 0 confirmed, archive ok; gate 42542329406 32
  blocking, baseline-difference kind). PRs #20, #21 marked merged. Development head: `53a56d3`. The three overnight batches are
  all merged. Next: `wip/b25-backlog` (strict 42589325057 FAILED: under investigation; closed 2026-11-09: the failures were net_fault_test/net_mp4_test CI timing, see the 17:30 UTC entry above and docs/decisions/B25-CI-FLAKE-C9DA5DB.md) and the PROP-03 test `b727954`.
- **2026-11-09 09:40 UTC: PROP-06 MERGED into `wip/b25r2-rev2` at `96b071c`** (fast-forward from `229f76e`; merge of `229f76e` and
  `a7071aa`; strict Tests 42587815471 on `96b071c` passed). PRs #16, #17, #18 marked merged by GitHub. PROP-03 eviction-path test
  `b727954` on `wip/b25-prop03` (5/0 on `96b071c`; 3 failures with `f0a854c`'s property.gd; the commit message says 4, wrongly).
  Development branch head: `96b071c`. Next merges: JUS-04/REG-07 (`wip/b25-next-batch`, recorded campaign 42570299554), then
  `wip/b25-backlog` (strict CI dispatched), then PROP-03's test.
- **2026-11-09 08:40 UTC: LIFE-03/04 MERGED into `wip/b25r2-rev2` at `229f76e`** (merge of `f0a854c` and `494af9a`; the merged tree
  is `494af9a`'s, the tested tree). Evidence: strict 42530864510 passed; recorded campaign 42557922632 (record: true): seed 1
  365/365 0 CRITICAL 17 HIGH 46 MEDIUM 0 confirmed; seed 2 365/365 0/91/35 0 confirmed; archive ok. PROP-06's recorded campaign
  42557925404 on `a7071aa`: identical results (its settlement runs only when a household leaves). PROP-06 merge commit `96b071c`
  (on `229f76e`) is on `wip/b25-prop06-merge` under its own strict run before it reaches the development branch.
- **Overnight backlog (owner 2026-11-09 directive), `wip/b25-backlog` on `f0a854c`:** LIFE-05 `cbd91f6`, BIZ-03 `93327ae`,
  BIZ-04 `3e9b9a1`, TRD-02 `36fa011`, INV-04 `969a8f4`, INV-05 `e42a37f`, each with a new regression test (red on the old code,
  green now) and related suites 0 failures. EMP-03: the code already counts everyone seeking work (no change). SAV-02 in progress
  (earned_at_dawn, laboured_today, the market snapshot and the hour caches are not saved; a load resets them).
- **Status 2026-11-09 06:40 UTC (historical).** Three batches wait only on 365-day campaigns with the flight
  recorder on:
  - LIFE-03/04 `wip/b25-features-integration` `494af9a`: strict 42530864510 passed; gate 42530880459 33 blocking
    (baseline-difference kind). Campaign 42536147616 was dispatched with `record: false` by mistake (365/365 both seeds, no fatal
    stop, no leaks, but no recorder findings: not comparable); record:true campaign dispatched 04:20 UTC.
  - PROP-06 `wip/b25-prop06-integration` `a7071aa` (corrections 6e02171 + 2a37653 + LIFE-04 fix d6e9994 + brush-off): strict
    42535255473 passed; gate 42535257321 33 blocking (baseline-difference kind, the +1 from LIFE-03/04). record:false campaign
    42540721533 365/365 clean of fatal stops; record:true campaign dispatched 04:20 UTC.
  - JUS-04 + REG-07 `wip/b25-next-batch` `4f1b3c8` (PRs #20/#21 on f0a854c, focused workflows dropped, floors jus04 6 and
    intel_test 20; red/green: 1 and 5 failures on f0a854c's code): local related suites 0 failures; strict 42542326507: 11 shards
    passed, shard 9 (demo_test) crashed natively once (double free, all checks before it ok) and passed on re-run (the run reads
    "failure" only because the report job reads re-run artifacts alone); gate 42542329406: 32 blocking, the 20 printed all
    baseline-difference. record:true campaign dispatched 06:00 UTC.
  - Merge order once clean: LIFE-03/04, then PROP-06 (it contains #16/#17), then JUS-04/REG-07 (close PRs #20, #21).
  - Disk: about 156 MB free; no new worktrees (merges by plumbing).
- **Features after Batch A:** LIFE-03/LIFE-04 `wip/b25-features-integration` `494af9a` = `46d934c` + LIFE-04 integration fix (a living
  partner always blocks courting/marriage; PR #17's `free_to_partner` let a living partner with a one-sided link count as free:
  aspiration_test 3 failures in strict runs 42524437969/42524448237). Strict Tests 42530864510 on `494af9a`: passed. Gate
  42530880459: 33 blocking, all of the baseline-difference kind (one more day-10/30 value than the dev branch's 32, from the
  features' changed village; determinism identical); 365-day campaign not yet run on `494af9a`. PROP-06 `wip/b25-prop06-integration`
  `a7071aa` (= PROP-06 correction 6e02171 + hut fix 2a37653 + the LIFE-04 fix d6e9994 + the brush-off fix): strict and gate
  dispatched; on `d6e9994` the only failure was start_test (the brush-off bug, fixed in Batch A).
- **(historical) 12-CORRECTION MERGE CANDIDATE (owner directive 2026-11-08 "Build 25 audit integration and merge"):** `wip/b25-audit-integration`
  `f0a854c` = `0d252b4` (the 11 corrections, PRs #5-#15) + the B25R2-BRUSHOFF fix (`dialogue.gd` empty-plan guard;
  `brushoff_empty_plan_test` 5/0, 1 failure with the same SCRIPT ERROR on the old code; floor 5). Strict suite on `f0a854c`:
  dispatched 20:16 UTC. Gate and campaign evidence reused from `0d252b4` (gate 42509523836; campaign 42515726815, segment 1 clean
  on both seeds, still running) because brush_off is called only from main.gd's player talk, never by the simulation. The gate's 32
  blocking findings are the development branch's own (baseline df67e8e, attributed in SIM_BASELINE_DIFFERENCES_B25R2.md); the
  equilibrium values are identical to the generation 8 candidate: no regression, baseline acceptance stays the owner's.
  Merge into `wip/b25r2-rev2` when the strict suite is 0 failed / 0 script errors and the campaign is clean.
- **Owner-approved features, separate:** `wip/b25-features-integration` `46d934c` = the 12 + LIFE-03 (PR #16, with an integration
  correction: its healing guard excluded nobody because Skills.level is 1 when untrained; now level 2) + LIFE-04 (PR #17) +
  `owner_features_integration_test` (16/0; 3 failures with PR #16 as merged). Runs on `46d934c`: tests 42517545415, gate
  42517547863, campaign 42517550077. PROP-06 (PR #18) on `wip/b25-prop06-integration`: corrected
  at `6e02171` under the owner's 2026-11-08 PROP-06 directive (saved in docs/directives): one planned, preflighted, rollback-safe
  departure settlement (estates whole, let property sold with the lease kept, own leases surrendered, nothing on insolvency,
  nothing when only part of a household goes). prop06_estate_transaction_test (the directive's 18 cases, floor 57): 57/0, 19
  failures on PR #18's code. settle_review_test (5) and migration_test (1) already failed on `a69069f`: they assumed no sale
  proceeds; expectations now add them (same exact equalities). Ten related suites 0 failures locally. Strict CI and gate
  dispatched on `6e02171`. Interactions: BIZ-04 venture tills follow keep_till's venture_owner rule (tested, case 18); INV-04
  stash is player-only, so NPC migration does not touch it; PROP-03 leased sites go through Property._release; REG-02 (stale
  journey, trade credit) is outside the settlement and unchanged; REG-05 must call the settlement where the walk starts.
  Finding, not fixed: an owned hut that is not a "home" type (the Lorekeeper's) is not in Property.held_by, so it is neither
  sold nor surrendered. MP-05 (PR #19) on
  `wip/b25-mp05-integration` `767ea22` (chests.gd conflict with INV-03 resolved, MP-05's superset kept): blocked on the security
  verification the owner listed (real host/guest, modified clients, reconnect, UI menus, privacy, tools/property outside chests).
  **MP-05 verification, 2026-11-09 (partial):** code review of PR #19 found two defects, both fixed with tests:
  (1) revoking a tier-3 agreement left a former partner pulling the other's cart (`Carts.update` now lets go when `may_use`
  fails; mp05 test +2 checks, 1 failure on the old code; floor 22 -> 24); (2) MP-05's `Carts.park` guard stopped the
  simulation parking villagers' carts (home_test 3 and underground_struct_test 1 failures on `767ea22`; guard now only stops a
  player releasing another player's cart). Commits `a898541`, `be307f8` on `wip/b25-mp05-integration`. That branch's full run
  42626491122 failed settle_review (5), aspiration Q8 (3), migration (1): the raw PR #17/#18 code it carries, already fixed on
  the dev line. MP-05 rebased onto the backlog merge as `wip/b25-mp05-on-dev` `242ca83` (c9da5db + PR #19 + both fixes): full
  CI 42636628469 green; those three suites 0 failures locally. Verified by review: chest takes filtered by tier (`goods`),
  offer tier bounded 1-3, per-guest privacy of `asset_shares` (`_private_for`, MP-07), mutual revocation. Not yet done:
  real two-device host/guest, modified-client request forging, reconnect, UI-menu walk. Limitation: a promoted guest after host
  loss holds only its own pairs' agreements (same as offers). Next: merge `242ca83` onto the dev line after the backlog merge
  lands (its own gate/campaign decision).
- **(historical) AUDIT INTEGRATION (owner directive 2026-11-08, "Audit fix integration"): 11 corrections, PRs #5-#15.** Branch
  `wip/b25-audit-integration` from `wip/b25r2-rev2` `fe7d8f8`; tested head `0d252b4` = all 11 merged (merge order #5, #9, #10-#15,
  #6-#8; code merged clean; tests.yml conflicts resolved by keeping every line) + floors for the five suites of #5-#9 (6, 7, 8, 13,
  9, measured). PR heads: #12 `04913e2` PROP-04, #13 `f85fe0a` JUS-01, #14 `ff2f4c4` INV-03, #15 `47a6dc9` MP-01 (others below).
  - Stage A (local): the 11 audit suites 87 checks, 0 failures, 0 script errors; every count equals its floor.
  - Strict suite 42509510188 on `0d252b4`: 239 game suites, 238 passed, 1 failed: start_test 523/0 with 1 SCRIPT ERROR, the
    pre-existing B25R2-BRUSHOFF (`dialogue.gd:526`, untouched by every PR; also on `fe7d8f8`). Python suite and the 10-day economy
    run (leak 0) passed. **Blocker for the merge: the owner's decision on B25R2-BRUSHOFF.**
  - Gate (in 42509523836): the same as `1f2ff4f`'s: 32 blocking findings, all differences from the old accepted baseline; eq_s1/eq_s2
    at days 10 and 30 identical to the generation 8 candidate in every value; non-blocking differences only in the randomised
    rot_ scenarios. No determinism or conservation finding.
  - 365-day campaign: run 42515726815 on `0d252b4` (the first request skipped it: a flight campaign with gate=true does not run).
  - Not merged into `wip/b25r2-rev2`; the 11 draft PRs and their branches are kept until the merge.
- **Seven audit corrections (69 records; 7 runtime-reproduced, 7 corrected in isolation, 7 draft PRs, 0 merged), each a DRAFT PR based on `wip/b25r2-rev2` `fe7d8f8`
  (= the audited commit), each passed its own focused Godot test; NOT integrated, NOT closed** (retrieved 2026-11-08):

  | PR | Finding | Head | Code change | New test |
  |---|---|---|---|---|
  | [#5](https://github.com/verbal76/My-Medieval-Life/pull/5) | MP-04 free cart | `325dcad` | net_actions.gd: `carts.place` off VERBS | mp04_cart_gateway_test |
  | [#6](https://github.com/verbal76/My-Medieval-Life/pull/6) | PROP-01 cancel foreign site | `683dfa9` | net_actions.gd: cancel_site owner + own-pack gate | prop01_cancel_site_test |
  | [#7](https://github.com/verbal76/My-Medieval-Life/pull/7) | PROP-05 foreign shop sale | `c1a40eb` | net_actions.gd: `business.sell` off VERBS | prop05_guest_sale_test |
  | [#8](https://github.com/verbal76/My-Medieval-Life/pull/8) | PROP-02 foreign fitting removal | `cc9d432` | fitting.gd: remove checks fit_refusal | prop02_fitting_owner_test |
  | [#9](https://github.com/verbal76/My-Medieval-Life/pull/9) | JUS-03 heir pursued | `1ca1c8e` | life.gd: justice.on_death at old-age death | jus03_old_age_justice_test |
  | [#10](https://github.com/verbal76/My-Medieval-Life/pull/10) | LIFE-01 retirement payroll | `56e9514` (fix `ed6ce70`) | life.gd: employment ended, owed goods back, before retirement | life01_retirement_payroll_test (10/4 -> 10/0; floor added) |
  | [#11](https://github.com/verbal76/My-Medieval-Life/pull/11) | SAV-01 famine on reload | `4eb2798` (fix `f5287a2`) | world.gd: food_days saved, legacy recomputed | sav01_famine_reload_test (5/3 -> 5/0; floor added) |

  Each PR also adds its test line to tests.yml and a verification note in docs/audits/ (on its branch).
  **Merge check (local, nothing pushed):** the three net_actions.gd edits touch different lines and merge cleanly; #5 and #9 merge
  clean; #6, #7 and #8 conflict **only in .github/workflows/tests.yml** (each adds its line at the same place: keep all five
  lines). Inline `# ...` comments on those lines are safe (ci_report reads them with shlex comments=True).
  **Seven-PR merge check (local, nothing pushed, 2026-11-08):** #5, #9, #10, #11 merge clean (the #10/#11 floor edits included);
  #6, #7, #8 conflict only in tests.yml. **Integration plan (when authorized):** on a new branch from `wip/b25r2-rev2`, merge #5,
  #9, #10, #11, #6, #7, #8 in that order, resolving tests.yml by keeping every line; add floors for the five suites of #5-#9 to tools/ci_check_floors.json (they have none: the
  strict count/floor rule does not yet hold them) and their timings; run the five tests, then the existing multiplayer suites
  (net_g1, net_c, net_ui, net_cave, net_interact, net_mp4, net_fault, net_econ_integrity, net_family, net_fauna), life/justice
  suites (aging, chapel, justice tests), fitting and business suites, then the full strict suite and the gate on that exact commit.
  Also, for #10/#11: LIFE-01 changes simulation outcomes (wages stop at retirement) and SAV-01 adds a save key, so after
  integration run the save suites (save_exact, save_continuity, save_transfer, plan_continuity, migration fixtures), the gate, and
  one 365-day campaign (its segment round trips); the generation 8 baseline candidate from `1f2ff4f` will likely no longer apply,
  and a new candidate needs the owner (never re-recorded automatically). Close each finding in the register only after those runs,
  citing their SHA. Keep all seven PR branches until then.
- **Monday, in priority order (each only once the owner authorizes it):**
  1. The owner's generation 8 baseline decision (TEST-AUDIT-Q2).
  2. The owner's decision on B25R2-BRUSHOFF (a one-line guard, with a test) and on seed 1's warnings (investigate or accept).
  3. On `wip/b25r2-rev2`: the label "0.1.34 Rev 2 — Playtest 1", `door_exit_test` `7971720`, the DECISIONS entries (`adf71ec`,
     `c903ce8`, the four playtest fixes), the brush-off fix if approved.
  4. The full strict suite and the gate on that exact commit; a new baseline candidate if its eq_s1/eq_s2 differ from `1f2ff4f`'s.
  5. The package from that commit, then the private draft release (B25R2-DRAFT-01). Never public, never Steam.
  6. The owner's real PC and controller playtest of it (stutter, caves with a guest, 4 players, Host a game).

## DEVELOPMENT HOLD after the current validation (owner, 2026-11-06 night; `docs/directives/2026-11-06_complete_validation_preserve_hold.md`)

Resume here. No new development, workflows, rebuilds, baseline promotion or publication until the owner authorizes it.

- **Candidate:** `wip/b25r2-playtest` at `1f2ff4f33da2d2df60ef876d2cb6a5eaf896b655` (= `832f711` + homestead water `c903ce8` +
  TEST-AUDIT-Q1 plans `adf71ec` + audit merge `4bfd8fd` + floor). Evidence table: `docs/release/B25R2_COMPLETION_CHECKLIST.md`.
- **Verified on `1f2ff4f`:** strict full suite 42297632580 (234 suites, 18,918 checks, 0 failures, 0 script errors); release run
  42297641550 (six packages, Windows smoke full and demo passed; gate red on the baseline only; release step skipped).
- **Owner's provisional playtest package (B25R2-PKG-01):** `pkg-full-windows`, artifact 13542782040,
  https://github.com/verbal76/My-Medieval-Life/actions/runs/42297641550/artifacts/13542782040, sha256 `259770e0...31df`, expires
  2026-12-06. Never alter or replace it.
- **365-day campaign on `1f2ff4f` (run 42297637074): FINISHED, clean.** Both seeds 365/365, 0 CRITICAL, 0 confirmed defects;
  seed 1 48 HIGH (was 20 on `832f711`: an open, uninvestigated finding), seed 2 99 HIGH. The `832f711` campaign 42274347279
  finished too (its one defect, homestead water, fixed in `c903ce8`).
- **STOPPING POINT: generation 8 baseline (TEST-AUDIT-Q2).** Candidate `docs/release/sim_baseline_candidate_gen8.json` (commit
  `1f2ff4f`, gen 8, save 23) and its comparison in `docs/release/SIM_BASELINE_DIFFERENCES_B25R2.md`: every difference attributed
  (the band household `bf20dc9` + generations 6-8), leaks 0, determinism identical. Accepted baseline unchanged. Wait for the owner.
- **Owner's playtest fixes on `wip/b25r2-rev2` (from `1f2ff4f`), local tests only, not in CI:** `6f23933` hosting for 4
  (B25R2-HOST4), `5d07527` guest stuck outside a cave (B25R2-CAVE), `ef8141a` Host a game on the title (B25R2-HOSTMENU), `ed221df`
  + `fe7d8f8` tiles made at the start, the freeze south of the village (B25R2-STUTTER). Evidence: `docs/release/B25R2_COMPLETION_CHECKLIST.md`.
- **Then (after the owner's baseline decision):** on `wip/b25r2-rev2` add the label "0.1.34 Rev 2 — Playtest 1" (B25R2-VER-01),
  `door_exit_test` `7971720`, the DECISIONS entries (`adf71ec`, `c903ce8`, the four playtest fixes); full strict suite and gate on that
  exact commit (the candidate applies only if its eq_s1/eq_s2 values match; else a new candidate); private draft release only
  (B25R2-DRAFT-01). Never public, never Steam.
- **Audit:** `docs/audits/2026-11-06_TEST_REGIMEN_AUDIT.md`: 12 testing defects all repaired (T13 = gap G2), 10 coverage gaps, 8 open.
- **Records:** this branch, `wip/requirements-control` (register 0 problems). Audit branch `wip/test-audit` (`7971720`).

## B25R2 checkpoint (2026-11-06 12:50 EST)

Play Test Build One repairs on `wip/b25r2-playtest`, head `cb5e323` (base F2 `20e579e`). Live checklist with evidence:
`docs/release/B25R2_COMPLETION_CHECKLIST.md`. Full suite on `f3c5bdd` dispatched (tests.yml on wip/b25r2-playtest).
Next: read it; the 4 remaining bridge loops; the 365-day campaign on the final commit; the Windows package (not to be
published without the owner's approval).

## Owner decision 2026-11-05: B25R1 audit, Option 1 (B25R1-AUDIT-OPT1; controls this session)

- **Directive:** `docs/directives/2026-11-05_b25r1_audit_option1.md`. Finish validating the current code (`wip/b25r1`, head `a995397`)
  while developing every approved B25R1 requirement; no deferral without the owner. The audit
  `docs/audits/B25R1_REQUIREMENTS_AUDIT_2026-11-05.md` is the working completion checklist.
- **Live completion report:** `docs/handoffs/B25R1_COMPLETION_REPORT.md` (counts, per-requirement table, SHAs and runs, what to repeat
  when the final SHA changes). **Owner questions** (seven groups, asked one at a time): `docs/handoffs/B25R1_OWNER_QUESTIONS_2026-11-05.md`.
- **New register ids (in development, grass-and-map worker, branch wip/b25r1-grassmap once created):** B25R1-023 Bow.Pixel Low Grass
  decoration on the overworld; B25R1-024 region map restyle (UIStyle, gamepad focus on the Village tab).
- **Economy decisions (owner 2026-11-05, questions 20-27):** B25-ECON-P1..P3 integrated (edf1854); B25-ECON-P5 land clearing integrated (c3d9d91); B25-ECON-P4 own-settlement ore consignment integrated (c3d9d91), cross-settlement consignment (owner question 27) integrated (e097fab).
- **Aerial maps (owner 2026-11-05, B25R1-025):** region and village maps drawn from the player's generated world, for tonight's private playtest; integrated 58cc720; B25R1-026 (settlements never hidden by discovery, owner question 31) in development on wip/b25r1-aerial.
- **Tonight's private playtest package: shipping checklist (owner 2026-11-05):** all four must be merged into wip/b25r1 and pass on the final integrated commit before packaging: (1) aerial maps B25R1-025/026; (2) Wood Perilous outline and remaining visual defects (wip/b25r1-wood); (3) economy follow-up (wip/b25r1-econ4: Higham collection stop, consignment policy review); (4) multiplayer: net_c host-restart defect fixed and merged (9655bfd), net_interact intermittent and host-restart persistence of identity, inventory, money, relationships and records verified (wip/b25r1-net5); all 12 net suites green on the final commit. Then full Tests, split simulation gate and baseline, packages with Windows smoke.
- **2026-11-06 03:04 UTC: candidate F2 = `20e579e` on wip/b25r1** (F `a9e9f6e` + wip/b25r1-fixhh + wip/b25r1-fixmap + wip/b25r1-fixdet
  + DECISIONS). F failed its gates (gate 42124898077 det_s1; Tests 42124894260: 5 suites); all five suites and the determinism cause
  are fixed (records: `docs/release/B25R1_FAMILY_PLAYTEST_RECORD.md`). Running on F2: Tests 42154221632, split gate 42154224992, 365-day
  twin campaign (new, on F2). Next: baseline reconciliation (sim_gate.py --write asks), then the freeze per
  docs/directives/2026-11-05_b25r1_family_playtest_now.md (automatic only when every gate passes). Family playtest published:
  release build-34 from F (https://github.com/verbal76/My-Medieval-Life/releases/tag/build-34), full Linux pending the corrected build.
- **FROZEN 2026-11-05 22:50 UTC: F = `a9e9f6e` on wip/b25r1** (net5 merged 12a8dce, contract_50ore test accounting 30b7864,
  journey save stability fb64eab, econ5 decisions 32/33 merged a9e9f6e). No merges into wip/b25r1 during validation. Running on F:
  Tests 42124894260 (12 shards), split simulation gate 42124898077, 365-day twin campaign 42124902114 (independent; holds the package
  only if it shows the build unsafe). Next: baseline reconciliation (`tools/sim_gate.py --write` asks permission) to commit P, then
  release.yml private on P. Watch on F: net_fauna, net_econ_integrity 20% loss, net_fault host-killed (single earlier failures);
  homestead_test failed once on the gen 6 world (0f6921e), passes on gen 7.
- **Treasury ore recovery (owner 2026-11-05, B25-ECON-P7):** in development on wip/b25r1-econ6; not a blocker for tonight's private playtest (merged only if ready before final validation).
- **Other ordered work (Option 1 item 2):** B25R1-018 Bear Hill and castle knoll; B25R1-022 Fantasy Lands houses; B25R1-010 player
  homestead well; B25R1-020 Android crowd-management measurement. EA-01 tracked separately (milestone: Early Access demo about
  2026-11-24; build placement is the owner's).

## Build 25 Revision 1 (owner, 2026-11-03)

> **HISTORICAL (marked 2026-11-09, HAG-AUTH-01).** Revision 1's integration line `wip/b25r1` is frozen; the current line is in the pointer at the top of this file.

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

> **HISTORICAL (superseded 2026-11-03; marked 2026-11-09 by the documentation agent).** This table describes `wip/expansion20`
> and the 2026-11-02 standby. The current position is the "CURRENT BUILD 25 STATE" pointer at the top of this file.

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
| Packaging and release | No Build 25 package exists. Packaging needs the owner's authorization. No public release. *(Historical, 2026-11-02; since then `build-34` (B25R1) was published publicly on 2026-11-06.)* |
| Living Economy | Integrated but **off** by default. It switches on by default once the 13 LE-07 readiness gates pass on the integrated candidate, with no further approval (B25-LE-ACTIVATE-D1). |
| Operating mode | **STANDBY** (owner, 2026-11-02, MML-CONSERVE-01): MML is second priority behind Upwardly. At most one Claude worker; no parallel investigators, background sessions, scheduled follow-ups, new features or 365-day campaigns without the owner's approval. Nothing is being worked on. |
| GitHub Actions | **Running, the one final campaign (owner B25-CLOSE-02) on `4b51c92`:** flight [41536805310](https://github.com/verbal76/My-Medieval-Life/actions/runs/41536805310) (seeds 1 and 2, 365 days, every 10, 100-day segments, recorded) and economy-on [41536810831](https://github.com/verbal76/My-Medieval-Life/actions/runs/41536810831) (seed 1, `--market`, 365 days, every 10). Do not cancel, rerun or duplicate (SIM-02). Done: Tests 41509578455 on `0d194c8` green (full CI, reused). |

## Workers and branches (recovery records)

> **HISTORICAL (2026-11-02 workers; marked 2026-11-09).** The current worker inventory is at the top of this file.

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

> **HISTORICAL (evidence on `wip/expansion20` SHAs up to 2026-11-02; marked 2026-11-09).** For current evidence see the changelog's
> 2026-11-08/09 entries and `docs/decisions/B25-VALIDATION-2026-11.md`.

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

> **HISTORICAL (as of 2026-11-02/03; marked 2026-11-09 by the documentation agent).** The current open limitations are in `docs/KNOWN_ISSUES.md` (KI-06 to KI-14 added 2026-11-09) and the audit register.

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

> **HISTORICAL (as of 2026-11-02/03; marked 2026-11-09 by the documentation agent).** The current list is in the pointer at the top and in `docs/requirements/views/DECISIONS.md`.

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

> **HISTORICAL (as of 2026-11-02/03; marked 2026-11-09 by the documentation agent).** This list is the 2026-11-02 plan for `wip/expansion20`. The current next actions are in the pointer and the worker inventory at the top. The 2026-11-08 "continuous engineering" and 2026-11-09 overnight directives authorize the present work.

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
