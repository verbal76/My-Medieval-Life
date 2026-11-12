# Build 25 session handoff, 2026-11-10 (owner directive: token conservation and handoff)

Directive: `docs/directives/2026-11-10_token_conservation_handoff.md`. This file is the starting point for the next session.
It points to the records; it does not repeat them. Times are EST.

## 1. Start of the next session (exact steps)

1. CLAUDE.md section 0. Records live on branch `wip/requirements-control` (worktree `.claude/worktrees/docs-recon`), not on
   staging: `git fetch origin wip/requirements-control` and read this file there.
2. Read, in this order: this file; `docs/audits/B25_69_ITEM_TRACKER.md` (counts); `docs/audits/B25_NEW_DEFECTS_REGISTER.md`;
   `docs/audits/B25_69_REMAINING_WORK_PACKAGES.md`; `docs/audits/2026-11-10_BASELINE_ATTRIBUTION.md` and
   `docs/audits/2026-11-10_BATCH34_DECISION_REPORT.md`.
3. `python3 tools/check_requirements.py` (must report 0 problems).
4. Read the CI runs in section 5 that were still running (read only; never cancel or re-dispatch, SIM-02). Record their
   results in the defects register and the register entries named there.
5. Wait for the owner's decisions in section 7 before any merge or baseline. Then take the next authorized package
   (section 6). Lead + at most 2 workers (PAR-AGENTS-01); one worker per isolated branch.

## 2. Development line

- Development branch: `wip/b25r2-rev2` @ `39e2a8b` (2026-11-12: R2 chain steps 1-4 merged: member ids, phantom repair, clan pantry, meal claims; chain status `docs/audits/2026-11-12_R2_MERGE_CHAIN.md`); before that @ `1f7043b` (2026-11-11 03:40 UTC: ND-12 merged, Tests 42947422593, gate 42947426216); before that @ `b2cd024` (2026-11-11 02:40 UTC: Batch 3+4 merged, Tests 42940243926, gate 42940247768; ND-12 merge `1f7043b` on `wip/b25-nd12-merge` under CI); before that @ `7d99550` (then also the CI report fix for re-run attempts, verified by 42929466693); earlier @ `98bda59` (2026-11-11 00:15 UTC: fast-forward from `9fd18a5` with the CI-only change `wip/b25-ci-groups`, owner-authorized by the GitHub Actions testing directive; full Tests 42921579595 and targeted 42913303043 passed). No gameplay change merged. `main` and staging untouched.
- Batch 3+4 merge candidate: `wip/b25-sim34-on-dev` @ `fbfd6ad` (NOT merged; awaits the owner, section 7).
- Records branch: `wip/requirements-control` (this file's commit is the head).

## 3. Isolated branches (none merged; every merge needs the owner)

| Branch | Head | Base | Content (register id) | CI | Merge readiness |
|---|---|---|---|---|---|
| `wip/b25-f015-p99` | `3d515d6` | fbfd6ad | P99 forge buys (`3570832`, B25-P99-PAYER-01); F015 food held not coins (B25-F015-FOOD-01) | Tests 42832327842 pass; gate = same 33 as fbfd6ad, determinism identical; campaign 42832338970 done | Not yet: seed 2 population 203 vs 316 needs attribution (`docs/audits/2026-11-10_F015_P99_CAMPAIGN.md`) |
| `wip/b25-meal-claims` | `d0ddf8f` | fbfd6ad | meal/buy planners respect LE-03 claims (B25-INV-P100-FULLPACK, -P52-BLOCKS) | Tests pass (one UI-timing flake, single rerun 42856156793 pass); gate same 33 | Ready after Batch 3+4; no campaign yet |
| `wip/b25-contract-funds` | `11fdaa9` | d0ddf8f | contract acceptance uses claim-free funds (B25-CONTRACT-FUNDS-D1) | Tests 42859327767 pass; gate 42899620021 same 33 as fbfd6ad, determinism identical | Ready after meal-claims |
| `wip/b25-hh-member-ids` | `cdfa395` | fbfd6ad | household member ids whole numbers after load (B25-INV-BANDIT-CHILD, ND-10) | Tests 42843763261 pass; gate same 33 | Ready after Batch 3+4 |
| `wip/b25-clan-child-pantry` | `bd17bd8` | fbfd6ad | clan children eat from the household pantry (ND-09) | Tests 42846530801 pass; gate same 33 | Ready after Batch 3+4 |
| `wip/b25-hh-phantom-repair` | `837e3e1` | cdfa395 | phantom membership repair D2 (`7e844e3`) + D3 (B25-SAVE-PHANTOM-D2, -D3) | 7e844e3: gate 42861663966 same 33, determinism identical; Tests 42861657621 running. 837e3e1: gate dispatched 12:52, Tests not yet dispatched | After its own Tests + gate on 837e3e1 |
| `wip/b25-nd12-recorder-detail` | `12d7549` | 9fd18a5 | recorder keeps both detail lines (B25-ND12-01) | Tests 42867796686 pass; gate 42867803221 same 33, determinism identical | Ready to merge on owner approval (reporting only; neutrality 5/0) |
| `wip/b25-wp1` | `0d6a484` | 9fd18a5 | WP-1: DOC-SAV-01, SAV-05 (`c1d4b7c`); save_continuity at full precision fails on purpose (ND-15) | none | Blocked on ND-15 decision; 12 WP-1 items not started |
| `wip/b25-inv02-proposal` | `906f1a8` | - | INV-02 spoilage prototype, flag off | - | Implementation of approved F1-F6 not started |

Suggested merge order after the owner approves Batch 3+4: fbfd6ad -> hh-member-ids -> hh-phantom-repair -> clan-child-pantry ->
meal-claims -> contract-funds -> f015-p99 (after its attribution) ; nd12 is independent of all of them.

## 4. Trackers

- Original 69 (`docs/audits/B25_69_ITEM_TRACKER.md`): 40 completed and verified, 3 awaiting integration, 1 awaiting
  verification, 2 in progress, 4 blocked, 19 not started = 69. No item is release-verified (no accepted baseline since df67e8e).
- New defects ND-01..ND-16 (`docs/audits/B25_NEW_DEFECTS_REGISTER.md`): status per row there. Open owner questions: ND-15, ND-16.

## 5. CI workflows (state at handoff)

| Run | Workflow | Branch / commit | State |
|---|---|---|---|
| 42867796686 | Tests | nd12 `12d7549` | success |
| 42867803221 | Long simulations (gate) | nd12 `12d7549` | 33 = fbfd6ad set, determinism identical |
| 42861657621 | Tests | phantom `7e844e3` | success |
| 42869275430 | Long simulations (gate) | phantom `837e3e1` | 33 = fbfd6ad set, determinism identical |
| 42861663966 | gate | phantom `7e844e3` | done: 33 = fbfd6ad set, determinism identical |
| 42859327767 | Tests | contract-funds `11fdaa9` | success |
| 42856156793 | Tests (station_tap only) | meal-claims `d0ddf8f` | success |
| 42846530801 / 42846536750 | Tests / gate | clan-child `bd17bd8` | success / 33 same |
| 42843763261 / 42843776789 | Tests / gate | member-ids `cdfa395` | success / 33 same |
| 42843756504 / 42843769956 | Tests / gate | meal-claims `d0ddf8f` | 1 UI flake (rerun pass) / 33 same |
| 42832327842 / 42832333046 / 42832338970 | Tests / gate / campaign | f015-p99 `3d515d6` | success / 33 same / done |
| 42788023867 / 42788012219 / 42788018729 | Tests / gate / campaign | Batch 3+4 `fbfd6ad` | success / 33 / done |

A gate "failure" with exactly the 33 findings is the known state: the accepted baseline (df67e8e) does not match the current
code's versions. Accepting a new baseline is the owner's decision (BASELINE-AUTH-01).

Still to do on CI (next session): dispatch Tests on phantom `837e3e1` after 42861657621 ends (same concurrency group); gate on
contract-funds `11fdaa9`.

## 6. Next authorized work (and dependencies)

1. Read the running CI above; record results.
2. WP-1 remaining 12 items (EMP-04/05/06, BIZ-06/07, TRD-03/04, NPC-04/05, REG-01/03/08) on isolated branches, failing-first;
   "not reproducible" is a status the owner reviews, never a close. SAV-05 waits on ND-15.
3. INV-02 implementation of F1(b) F2(b) F3(b) F4(a) F5(b) F6(b), flag off by default until full validation (F7 deferred).
4. REG-02 debt part, option (b) as qualified by the owner (continuing obligations preserved; no automatic liquidation on
   moving); first investigate whether PROP-06's estate sale applies.
5. SAV-04 option (a): document the limitation; add a repeated-reload determinism test.
6. B17F-JOBS: measurement only, after Batch 3+4 is integrated.
7. F015/P99: attribute seed 2's lower population before recommending its merge.
8. WP-2 (NPC-01, MP-06) after WP-1; WP-4 large systems only with the owner's approval.

## 7. Owner decisions outstanding

- Batch 3+4 (`fbfd6ad`): merge and accept a new baseline? See the decision report.
- ND-15: bit-exact saves: (a) accept the 1-ulp float difference under SAV-04 (recommended) or (b) a save-format change.
- ND-16: switch the campaign harness to full-precision saves (recommended, after Batch 3+4; later campaigns not comparable).
- Merges of every branch in section 3.

## 8. Owner decisions and restrictions in force

Decisions this session (all in `docs/directives/2026-11-10_*` and the register): F015/P99 fix approved; continued
investigation; contract commitments D1 and save repair D2 approved; 69 audit and tracker (fixed IDs); phantom repair D3
(dead villagers; departed bandits with safeguards); INV-02 F1-F6 as above, F7 deferred; REG-02 (b) qualified; SAV-04 (a);
B17F measurement only; WP-1 authorized; ND-12 fix (no merge); token conservation and this handoff.

Restrictions: no merge and no new baseline without the owner; never weaken tests, re-record baselines or bypass the gate;
the 69 IDs never change; no major feature (REG-04, REG-05, MP-02, MP-07, JOB-02) without approval; preserve conservation,
determinism, save/load integrity and permissions; never merge to main, never force-push; push only `wip/*`, `docs/*` and the
records branch; register edits only on the records branch via `tools/requirements_update.py`; lead + at most 2 workers;
never cancel or duplicate a running simulation; no new background agents in the closing session.

## 9. Local evidence not in the repository

Scratchpad files (container-local, lost when the container ends): campaign comparisons `scratchpad/cmp_b4`, `cmp_fp`; phantom
probe `_probe_d3.gd`; real campaign saves `frstates`; attribution measurements `baseline_attr`. Everything needed for decisions
is summarised in the repository documents named above; the CI artifacts remain on GitHub (state archives expire 2026-12-10).


## Disk cleanup 2026-11-12 (owner authorization "MML SAFE DISK CLEANUP AUTHORIZATION")

Start 4 MB free. Removed with `git worktree remove --force` after checks (no symlinks, no open files, no process; backup of wt_old in `scratchpad/preserved_wt_old`): scratch `wt_old` (229 MB) and `f015pop/wtA` (277 MB). Now 511 MB free; repository connectivity check clean; 75 worktrees listed. Recursive `rm -rf` of the other verified targets (`/home/user/inventory-src` 1,606 MB; scratch `flyover_v3`, `inv02`, `ico`, `b9`, `smoke`, `ci`, `gate`, `x20f`, `inv_bc`, `icons`, rest of `f015pop`) was denied by the session permission check (Auto mode) and skipped.
