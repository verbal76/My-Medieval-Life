# Historical coverage register, 2026-11-03 to 2026-11-09 (HAG-FORENSICS-01)

**Reconstructed 2026-11-09 (started 13:15 EST) by the documentation agent**, under owner directive HAG-FORENSICS-01
([`docs/directives/2026-11-09_permanent_development_forensics.md`](../directives/2026-11-09_permanent_development_forensics.md)),
on branch `docs/history-recovery-2026-11`. The lead integrates it into `wip/requirements-control`.

This is an **audit record**. It shows which development history from the period is recoverable from GitHub, where it is, and what
is still missing. It is not a status record:
- requirement and decision status lives in the register (`docs/requirements/requirements.json`);
- current work lives in [`docs/CURRENT_DEVELOPMENT_STATE.md`](../CURRENT_DEVELOPMENT_STATE.md);
- the chronology lives in [`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md).

## 1. Method and sources

**Where the period starts.** The last fully documented, verifiable checkpoint is the changelog's newest entry before this
recovery: "DEV-GOV-01 ... REGION-NAV-01 halted for review", records commit `a720fd1` (2026-11-03 00:42 UTC, 2026-11-02 19:42 EST).
- After it, the changelog had no entries at all until this recovery.
- [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) stopped at 2026-11-02.
- The decision-record index stopped at 2026-11-02.
- The state file kept being updated, but only as a stack of dated sections, with a stale "Position" table and an old
  verification stamp.

The audit covers 2026-11-03 00:42 UTC to 2026-11-09 18:15 UTC. No unresolved earlier gap was found: the 2026-11-01/02 work has
changelog entries.

**Sources examined.**

| Source | Scope | Count |
|---|---|---|
| Commits on every remote branch (committer date in the period) | `git rev-list --remotes --since=2026-11-03T00:42Z` | 666 commits (588 non-merge). 145 on `wip/requirements-control`; 521 on code, task and audit branches. |
| Remote branches with a commit in the period | `git for-each-ref` | 100 |
| Pull requests | #5-#21 in detail; #1-#3 for context (closed before the period) | 17 + 3 |
| Issues | #4 (audit tracking issue) and its 13 comments | 1 |
| GitHub Actions runs created 2026-11-03..09 | `actions/runs?created=2026-11-03..2026-11-10` | 219. By workflow: Tests 97, Long simulations 68, Build and release 8, win-smoke 5, Family playtest release 1, Requirements register 1, 39 focused audit and feature runs. Every run from 2026-11-07 on was listed one by one. Earlier runs were checked where a record cites them. |
| Releases | GitHub Releases API | `build-25` (draft), `build-34` (published 2026-11-06 01:52 UTC) |
| Owner directives in `docs/directives/` dated 2026-11-03..09 | read | 35 files |
| Lead session transcript | `/root/.claude/projects/-home-user/754052d8-...jsonl` (not in the repository): owner messages, the lead's tool calls and results, subagent hand-backs | 130 owner messages in the period |
| Audit register | `docs/build25-audit-register` (`257475c`): `docs/audits/2026-11-08_build25_master_audit_register.md` | 69 records, 13 audits |
| Per-PR evidence files | `docs/audits/2026-11-08_*` on `wip/b25r2-rev2` | 14 files (no JUS-04 or REG-07 file exists) |

**Not available.**
- **The ChatGPT conversations** in which the owner gave the 2026-11-08 audit decisions, and in which ChatGPT investigated and wrote
  PRs #5-#21. They are not in the repository or this machine.
  - Their content survives only where ChatGPT or the owner wrote it to GitHub: issue #4 comments, PR bodies and comments,
    commit messages, and the `docs/audits/2026-11-08_*` evidence files.
  - The cost figures in the audit register are the owner's report.
- **The 13 paid independent audit reports themselves.** They survive only as the owner's v14 register summary
  (`docs/audits/2026-11-08_INDEPENDENT_AUDIT_OPEN_ITEMS_v14.md`).
- **Raw outputs of subagents** that the lead launched before this session's transcript window. Their hand-back texts are inside
  the transcript.

**Classification** (directive section 7):
- **COMPLETE:** the evidence and rationale can be recovered from GitHub.
- **PARTIAL:** some of it is missing.
- **UNDOCUMENTED:** the evidence exists, but no adequate record existed. Recovered here where possible.
- **UNRECOVERABLE:** the source material could not be found.
- **NOT APPLICABLE:** routine activity.

"Before" is the state found at the start of the recovery. "After" is the state once this branch is integrated.

## 2. Summary counts

- **Meaningful events identified:** 64 (sections 3-6). Routine activity is grouped in section 7.
- **COMPLETE before the recovery:** 24.
- **Needed reconstruction:** 39 (35 PARTIAL and 4 UNDOCUMENTED before).
  - 29 are COMPLETE after the recovery, through the changelog entries, decision records, known-issue entries and recovered
    directives. Two of them depend on the lead running the register commands: HR-29, and HR-37's register half.
  - 10 remain PARTIAL, with the gap named in their rows: HR-02, 09, 10, 12, 27, 37, 52, 53, 58 and 60.
- **UNRECOVERABLE:** 1, HR-64, the ChatGPT reasoning behind the 2026-11-08 corrections beyond what was posted to GitHub.
- These counts come from the table rows (Before and After columns), not estimates.
- **Owner messages that existed only in the session transcript:** 87. They are now saved verbatim in
  `docs/directives/2026-11-0{3,4,5,6,8}_recovered_owner_messages.md` (records commit `1b39194`).
  - 84 had never been saved.
  - 3 had been saved only in condensed form.
  - Among them are four owner directives of 2026-11-08 that authorized every merge into `wip/b25r2-rev2`, including the
    approval of the B25R2-BRUSHOFF fix.
- **Register gap:** none of the 2026-11-08 owner audit decisions was in `requirements.json`. The audit register held them, on
  another branch. Section 8 gives the commands for the lead to run.

## 3. Build 25 closure on `wip/expansion20` (2026-11-03)

| ID | Event | Branch / commit | Agent | Owner decision | Existing record | Before | After | Missing / remaining uncertainty |
|---|---|---|---|---|---|---|---|---|
| HR-01 | REGION-NAV-01 S1-S8 integrated | `wip/region-nav` `b540971` | lead + workers | REGION-NAV-01, Q1-Q6 | register; records `2c084fc`, `e8a0d38`; `REGION_NAV_WORK_PACKAGES.md` | PARTIAL (no changelog) | COMPLETE (changelog 2026-11-03) | none material |
| HR-02 | VAL-AGENT-01 read-only validation agent | `region-nav-validate` at `d3b82c4` | validation agent | 2026-11-03 directive (saved) | records `072a877`; state file | PARTIAL | PARTIAL | The agent's own report is not committed. Only the lead's summary of it exists. |
| HR-03 | REPORT-TS-01, B25-FINISH-01, DEMO-01 directives | records | lead | owner directives (saved verbatim) | directives; checklist | COMPLETE | COMPLETE | none |
| HR-04 | CI run 41580777660: shard 0 Python failure, corrected in `da7c8c1`; owner's investigation brief | `wip/expansion20` | lead | owner message 2026-11-03 00:19 EST | `CI_RECORD.md` (`40a7977`) | PARTIAL (owner brief unsaved) | COMPLETE (brief recovered) | none |
| HR-05 | `od16_test` stale expectation, corrected in `c4c3490`; final flight on `c4c3490` clean | `wip/expansion20` | lead | B25-CLOSE-02 | `4bd2a13`, `d1a93f1` | COMPLETE | COMPLETE | none |
| HR-06 | Release 41624309659 failed at the gate (stale SHIPPED_FLAGS), corrected in `726ceeb`; release 41648387967 made the `build-25` draft | `wip/expansion20` | lead | DEMO-01 / B25-FINISH-01 | `f6fde4b`, `8b4565e` | COMPLETE | COMPLETE | none |
| HR-07 | Settlement draw-order fix `0efaf32`. The owner skipped the simulation gate for it ("let's skip the aim for this change and ship the builds", 2026-11-03 10:43 EST). Release 41666958781 on `a459186` replaced the draft's files. | `wip/expansion20` `a459186` | lead | owner chat message | `CI_RECORD.md` (`2d51800`, `33419de`) | PARTIAL (owner words unsaved) | COMPLETE | The release object `432836586` still names `726ceeb` as its target commit; its files are from `a459186`. Recorded in KNOWN_ISSUES (KI-07). |

## 4. Build 25 Revision 1 on `wip/b25r1` (2026-11-03 to 2026-11-06)

| ID | Event | Branch / commit | Agent | Owner decision | Existing record | Before | After | Missing / remaining uncertainty |
|---|---|---|---|---|---|---|---|---|
| HR-08 | B25R1 directives 001-020 and owner answers Q1-Q9 | records | lead | 17 directives saved verbatim | directives; register B25R1-* | COMPLETE | COMPLETE | none |
| HR-09 | The integration line moved from `wip/expansion20` to `wip/b25r1` (`a459186` is its ancestor) | `wip/b25r1` | lead | Owner directives of 2026-11-04 and 2026-11-05 name "Branch: wip/b25r1" and "Integration branch: wip/b25r1" (recovered messages) | state file "Build 25 Revision 1" | UNDOCUMENTED as a governance change: BRANCH-POL-01 and CLAUDE.md still name `wip/expansion20` | PARTIAL | No owner text amends BRANCH-POL-01. The owner's directives name the new branches, so the move was owner-directed, but the rule text was never updated. The CLAUDE.md change is proposed for the lead and owner (section 9). |
| HR-10 | Thirteen B25R1 worker branches merged into `wip/b25r1`: interact, map, ui, roads, travelers, region, settle, homestead, presence, water, recorder, terrain, CI | `wip/b25r1-*` | lead + up to 3 workers | B25R1-002..020 | register entries; state-file sections; `B25R1_COMPLETION_REPORT.md` | PARTIAL (no changelog; the reasons for each merge live in commit messages) | PARTIAL (changelog milestone added) | Worker briefs and hand-backs from before the transcript window are not committed. The per-merge test evidence is in the register `tests` fields and the completion report. |
| HR-11 | B25R1 progress audit (2026-11-03 19:53 EST) | records `9651a42` | lead | owner request (recovered) | `docs/audits/B25R1_PROGRESS_AUDIT_2026-11-03.md` | COMPLETE | COMPLETE | Its percentages are estimates and say so. |
| HR-12 | CI architecture: time-balanced shards, consolidated report, split gate, concurrent twins | `wip/b25r1-ci` `552826b`, `wip/b25r1-gatesplit` `81429e8`, `wip/b25r1-cicover` `27dfdd6` | lead | Owner directives of 2026-11-04 01:07 and 20:58 UTC, unsaved until now | commit messages; FLIGHT-REC-01 concurrency note `979804f` | PARTIAL | PARTIAL | No design record of the shard layout. The commit messages and `.github/workflows/` are the record. |
| HR-13 | `net_econ_integrity_test` timing-race correction | `wip/b25r1-net*` | lead | Owner approval 2026-11-04 18:47 EST ("Approved. Implement the targeted ... timing-race correction"), recovered | commit messages | PARTIAL | COMPLETE (approval recovered) | none |
| HR-14 | Treasury discrepancy traced to a repeated manor axe purchase; fix `a995397`; owner rule: no baseline until it is explained | `wip/b25r1-axe` `8d05942` | lead | Owner messages of 2026-11-04/05 (recovered) | `docs/handoffs/B25R1_VALIDATION_HANDOFF_2026-11-05.md` | COMPLETE | COMPLETE | none |
| HR-15 | B25R1 requirements audit; Option 1; owner questions 1-33 | records `0e80f3b`, `91db5c4`, answer commits | lead | B25R1-AUDIT-OPT1; answers recorded in register `owner_answer` fields | audit; directive; register | COMPLETE | COMPLETE | none |
| HR-16 | Economy P1-P7, aerial maps B25R1-025/026, Wood Perilous, generation 7 | `wip/b25r1-econ*`, `-aerial`, `-wood` | lead + workers | owner answers 20-33 | register | COMPLETE | COMPLETE | none |
| HR-17 | Experiments not merged: `wip/b25r1-econ4-exp` `f1189a7` ("EXPERIMENT (not for merge)": relaxed consignment switches, evidence for question 32); `wip/b25r1-detdebug` `2c02087` (debug trace of villager 39's coins for REC-D3) | branches as named | lead | not applicable | the commit messages; question 32 text in the register | PARTIAL | COMPLETE (changelog names them) | The experiment's run 42080417065 is cited in question 32. Its artifacts expire. |
| HR-18 | Freeze F = `a9e9f6e`; public family-playtest release `build-34` (published 2026-11-06 01:52 UTC, owner's visibility correction) | `wip/b25r1`, `wip/b25r1-family` | lead | 2026-11-05 directives (saved condensed; full text recovered) | `docs/release/B25R1_FAMILY_PLAYTEST_RECORD.md`; state | COMPLETE | COMPLETE | none |
| HR-19 | F failed its gates (det_s1 in 42124898077; 5 suites in 42124894260). F2 = `20e579e` (fixhh, fixmap, fixdet REC-D3) | `wip/b25r1` `20e579e` | lead | not applicable (repair) | B25R1_FAMILY_PLAYTEST_RECORD; state | COMPLETE | COMPLETE | none |

## 5. Build 25 Revision 2, "Play Test Build One" (2026-11-06 to 2026-11-07)

| ID | Event | Branch / commit | Agent | Owner decision | Existing record | Before | After | Missing / remaining uncertainty |
|---|---|---|---|---|---|---|---|---|
| HR-20 | Play Test Build One directive and the owner's four answers. The first answers were a mis-click, so the owner re-answered. | records `57c5f91`, `05564a7` | lead | B25R2-Q1..Q4 | condensed directive; register | PARTIAL (the directive was saved condensed) | COMPLETE (full text recovered) | none |
| HR-21 | B25R2 completion directive and testing-audit directive (2026-11-06 10:31 and 16:06 EST) | records | lead | owner directives | not saved before | UNDOCUMENTED | COMPLETE (recovered) | none |
| HR-22 | B25R2 repairs on `wip/b25r2-playtest`: riverbank autotravel, generation 8 bridges, pad reach. Candidate `832f711`; its campaign 42274347279 found a homestead-water save defect, fixed in `c903ce8`; candidate `1f2ff4f` | `wip/b25r2-playtest` `1f2ff4f` | lead | B25R2-Q1..Q4 | `docs/release/B25R2_COMPLETION_CHECKLIST.md` | COMPLETE | COMPLETE | Repro branch `wip/b25r2-repro` `21bc6ee` ("before figures; not for merge") is diagnostic. |
| HR-23 | TEST-GOV-01 and TEST-AUDIT-01: 9 mutations detected, 1 equivalent; 12 testing defects repaired; 10 coverage gaps, 8 open | `wip/test-audit` `7971720` | lead | owner directives (saved) | `docs/audits/2026-11-06_TEST_REGIMEN_AUDIT.md` | COMPLETE | COMPLETE | `door_exit_test` `7971720` is still not in a candidate. |
| HR-24 | Generation 8 baseline candidate. Not accepted: TEST-AUDIT-Q2 is PROVISIONAL and needs the owner's explicit final approval. | records `8dfc844` | lead | TEST-AUDIT-Q2 | `SIM_BASELINE_DIFFERENCES_B25R2.md`; register | COMPLETE | COMPLETE | Still open with the owner. |
| HR-25 | Provisional Windows package for the owner (artifact 13542782040); version label; draft conditions | `1f2ff4f` | lead | B25R2-PKG-01, VER-01, DRAFT-01 | register; directive (saved verbatim) | COMPLETE | COMPLETE | The artifact expires 2026-12-06. |
| HR-26 | Owner playtest defects, fixed on `wip/b25r2-rev2`: hosting for 4 (`6f23933`), guest stuck outside a cave (`5d07527`), Host a game (`ef8141a`), stutter (`ed221df`, `fe7d8f8`) | `wip/b25r2-rev2` `fe7d8f8` | lead | B25R2-HOST4, CAVE, HOSTMENU, STUTTER | register; checklist | PARTIAL (owner reports unsaved; CI coverage not stated) | COMPLETE | Their first CI run was the strict run on `f0a854c` (42519022430), which contains them. The real-PC check of the stutter fix has not been done. |
| HR-27 | Invite code too long: the owner chose an option; nothing started | not applicable | lead | owner messages (recovered) | state file "Unresolved" | PARTIAL | PARTIAL | The owner's chosen option is not in the register. |
| HR-28 | Development hold and Monday recovery point | records `babfb17`, `0798c0b` | lead | 2026-11-06 directives (saved) | state | COMPLETE | COMPLETE | none |
| HR-29 | B25R2-BRUSHOFF found by `start_test` on `fe7d8f8` | records | lead | approved 2026-11-08 ("PHASE 1 — CORRECT B25R2-BRUSHOFF / APPROVED") | register (disposition still OPEN) | PARTIAL (register stale) | COMPLETE once the lead runs the section 8 commands | none |

## 6. Independent audit and its integration (2026-11-08 to 2026-11-09)

| ID | Event | Branch / commit | Agent | Owner decision | Existing record | Before | After | Missing / remaining uncertainty |
|---|---|---|---|---|---|---|---|---|
| HR-30 | v14 audit register saved (69 records, 13 static audits, 0 runtime-confirmed); issue #4 opened | `docs/build25-audit-register` `83e2994`; records `02ad7aa` | lead | owner upload, 2026-11-08 02:30 EST | audit register; issue #4 | COMPLETE | COMPLETE | The audit reports themselves are UNRECOVERABLE (only the owner's summary exists). |
| HR-31 | Batch A corrections, PRs #5-#15. Each was reproduced red then green on its own runner: MP-04, PROP-01, PROP-05, PROP-02, JUS-03, LIFE-01, SAV-01, PROP-04, JUS-01, INV-03, MP-01 | `audit/*-20261108` | ChatGPT, via the owner's GitHub account (commits by "Hot Attic Games") | owner authorized the work in the ChatGPT conversation; issue #4 comments | PR bodies; `docs/audits/2026-11-08_*_VERIFICATION.md`; issue #4 comments 1-3 | COMPLETE (per PR) | COMPLETE; decision record [B25-AUD-BATCH-A](../decisions/B25-AUD-BATCH-A.md) | The ChatGPT reasoning beyond what was posted is UNRECOVERABLE (HR-64). |
| HR-32 | Failed first attempts in Batch A: INV-03 42506825276 (test-only type error, not defect evidence); MP-01 42507064870 (an earlier red that failed before the test was corrected) | PR branches | ChatGPT | not applicable | issue #4 comment 3 | PARTIAL | COMPLETE (decision record) | The MP-01 first red run's specific error was not read: low value. |
| HR-33 | Batch A integration: `wip/b25-audit-integration` `0d252b4`. Merge order #5 base, #9-#15, #6-#8; only conflicts in `tests.yml`, all lines kept; five floors added | `0d252b4` | lead | 2026-11-08 directives (recovered) | state; audit register | PARTIAL (directives unsaved) | COMPLETE | none |
| HR-34 | Strict run 42509510188 on `0d252b4`: 238 of 239 suites; `start_test` script error = B25R2-BRUSHOFF | `0d252b4` | lead | not applicable | state | COMPLETE | COMPLETE | none |
| HR-35 | BRUSHOFF fix `f0a854c` (fail-before: 1 script error; pass-after: 5/0) | `f0a854c` | lead | owner APPROVED 2026-11-08 15:12 EST | commit message; state | PARTIAL (approval not recorded) | COMPLETE | none |
| HR-36 | Batch A merged: `wip/b25r2-rev2` fast-forwarded from `fe7d8f8` to `f0a854c` at 23:36 UTC. Strict 42519022430 passed; campaign 42515726815 on `0d252b4` reused; gate 42509523836 | `f0a854c` | lead | directive (recovered) | state; audit register; issue #4 comment 13 | COMPLETE | COMPLETE | The campaign ran on `0d252b4`, not `f0a854c`. Reuse was argued because `brush_off` is player-only. That argument is recorded, not tested. |
| HR-37 | Owner decisions of 2026-11-08 on LIFE-03/04, PROP-06, MP-05 (two-way), JUS-04, MP-07, REG-04/05/07, BIZ-03 | issue #4 comments 4-12 | owner, posted by ChatGPT | as listed | issue #4; 2026-11-09 overnight directive; audit register reconciliation `257475c` | PARTIAL (not in `requirements.json`) | PARTIAL until the lead runs section 8 | The owner's words are only in the issue comments and the 2026-11-09 directive. The ChatGPT conversation is UNRECOVERABLE. |
| HR-38 | LIFE-03/04: PRs #16/#17, two integration defects found by the lead (`46d934c` healing level 2; `494af9a`/`d6e9994` living partner blocks); merged `229f76e` 08:40 UTC | `wip/b25-features-integration` `494af9a` | ChatGPT (PRs), lead (fixes) | LIFE-03, LIFE-04 | commit messages; state | PARTIAL | COMPLETE ([B25-AUD-LIFE-03-04](../decisions/B25-AUD-LIFE-03-04.md)) | none |
| HR-39 | PROP-06: PR #18 refused estates. Corrected `6e02171` under the owner's PROP-06 directive; hut fix `2a37653`; merged `96b071c` 09:39 UTC | `wip/b25-prop06-integration` `a7071aa` | ChatGPT, lead | PROP-06 directive (saved verbatim) | commit messages; directive; state | PARTIAL (no rationale record) | COMPLETE ([B25-AUD-PROP-06](../decisions/B25-AUD-PROP-06.md)) | none |
| HR-40 | JUS-04/REG-07: PRs #20/#21. Red run 42520518399 (6/1, 20/5); green 42520403018, 42520222693; first JUS-04 focused failure 42520219728 was a test setup mistake (regard clamps at 0) | `wip/b25-next-batch` `4f1b3c8` | ChatGPT, lead | JUS-04, REG-07 | PR comments; issue #4 | PARTIAL (no evidence file in `docs/audits/`) | COMPLETE ([B25-AUD-JUS04-REG07](../decisions/B25-AUD-JUS04-REG07.md)) | REG-07 thresholds (4/8/4 days) are ChatGPT's engineering choice inside the owner's 8-day maximum. Its measurement basis is not recorded. |
| HR-41 | Strict 42542326507 on `4f1b3c8`: `demo_test` crashed natively once (double free) and passed on re-run; the run reads "failure" because the report job reads re-run artifacts only | `4f1b3c8` | lead | not applicable | state; `53a56d3` message | PARTIAL | COMPLETE (KNOWN_ISSUES KI-09, KI-10) | The cause of the crash is uninvestigated. |
| HR-42 | `record: false` dispatched by mistake for three campaigns (42536147616, 42540721533, 42552442930) | as named | lead | not applicable | state | PARTIAL | COMPLETE (KI-11) | none |
| HR-43 | JUS-04/REG-07 merged `53a56d3` 11:04 UTC (strict 42597744977; recorded campaign 42570299554) | `53a56d3` | lead | directive | state; `53a56d3` message | COMPLETE | COMPLETE | none |
| HR-44 | Overnight directive 2026-11-09 (owner decisions reconciled) | records `07a1713` | lead | saved verbatim | directive | COMPLETE | COMPLETE | none |
| HR-45 | LIFE-05 `cbd91f6` (8/0, 3 red) | `wip/b25-backlog` | lead | LIFE-05 | commit message | PARTIAL | COMPLETE ([B25-AUD-BACKLOG-2026-11-09](../decisions/B25-AUD-BACKLOG-2026-11-09.md)) | none |
| HR-46 | BIZ-03 `93327ae` (12/0, 3 red) | same | lead | BIZ-03 Option B | commit; issue #4 comment 12 | PARTIAL | COMPLETE | none |
| HR-47 | BIZ-04 `3e9b9a1` (5/0, 2 red) | same | lead | BIZ-04 | commit | PARTIAL | COMPLETE | none |
| HR-48 | TRD-02 `36fa011` (6/0, 1 red) | same | lead | TRD-02 | commit | PARTIAL | COMPLETE | none |
| HR-49 | INV-04 `969a8f4` (9/0, 4 red) | same | lead | INV-04 | commit | PARTIAL | COMPLETE | none |
| HR-50 | INV-05 `e42a37f` (12/0, 4 red) | same | lead | INV-05 | commit | PARTIAL | COMPLETE | The commit says three related suites were "still running" when it was made; their results are not recorded. The full strict run on `c9da5db` covers them. |
| HR-51 | SAV-02 `f67afdb` (6/0, 4 red) | same | lead | SAV-02 | commit | PARTIAL | COMPLETE | none |
| HR-52 | EMP-03: no change needed (the code already counts every seeker) | not applicable | lead | EMP-03 | state; audit register | PARTIAL (no test cited) | PARTIAL | No test or code reference was recorded for "already counts". The decision record says so. **Resolved 2026-11-09 14:20 EST by the lead:** the code was read and the claim is not right for every seeker (ambitious lookers, homestead members, players not counted); see KNOWN_ISSUES KI-15. |
| HR-53 | PROP-03 eviction test `b727954` (5/0). The commit message says 4 red failures; the lead's later record says 3 | `wip/b25-prop03` | lead | PROP-03 | commit; state | PARTIAL (contradiction) | PARTIAL | Which count is right (3 or 4) was not re-measured. Both statements are kept. **Re-measured 2026-11-09 14:15 EST by the lead:** `prop03_eviction_site_test` with `f0a854c`'s `game/scripts/core/property.gd` on `242ca83`: 5 checks, 3 failures (site left on the parcel; delivered logs to the manor; parcel re-lettable); 5/0 with the current file. The commit message's "4" is wrong. |
| HR-54 | Strict 42589325057 on `f67afdb` failed only `net_fault_test` (1 check, ghost peer after 15 s); 54/0 locally | `f67afdb` | lead | not applicable | state ("under investigation") | PARTIAL | COMPLETE ([B25-CI-FLAKE-C9DA5DB](../decisions/B25-CI-FLAKE-C9DA5DB.md)) | none |
| HR-55 | Backlog merge `c9da5db`. Attempt 1 of strict 42607051457 failed `net_fault_test` and `net_mp4_test`; the lead judged CI timing and re-ran; attempt 2 passed; recorded campaign 42627103286; dev branch fast-forwarded 17:25 UTC | `c9da5db` | lead | overnight directive | state; commit | PARTIAL (the judgement's evidence was not written down) | COMPLETE (decision record) | The flake judgement is an inference. Neither test was re-run alone in CI. |
| HR-56 | MP-05: PR #19; review fix `a898541` (revocation); regression found by local cart suites, fix `be307f8` (park); old-branch failures (run 42626491122); rebase to `wip/b25-mp05-on-dev` `242ca83`; CI 42636628469 green; campaign 42664730920 running | as named | ChatGPT, lead | MP-05 (issue #4 comments 6-7) | commits; state | PARTIAL | COMPLETE ([B25-AUD-MP-05](../decisions/B25-AUD-MP-05.md)) | Two-device, modified-client, reconnect and UI checks are not done. |
| HR-57 | Gates 42530880459, 42535257321, 42542329406, 42607055494 (32 or 33 blocking findings, all baseline-difference kind against `df67e8e`); baseline not replaced | as named | lead | TEST-AUDIT-Q2 (owner: explicit final approval needed); the owner's 2026-11-08 directive ("Do not regenerate ... baselines") | state; commit messages | PARTIAL | COMPLETE ([B25-VALIDATION-2026-11](../decisions/B25-VALIDATION-2026-11.md)) | Only 19 or 20 of the 32-33 findings print in the gate log. The rest are assumed to be the same kind. |
| HR-58 | Seed-1 HIGH counts moved: 20 (`832f711`) → 48 (`1f2ff4f`, Batch A, next batch) → 17 (LIFE-03/04, PROP-06, backlog). Seed 2: 99 → 91 / 94 → 63 | campaigns | lead | not applicable | state | UNDOCUMENTED (never analysed) | PARTIAL (KI-06 records the numbers) | No attribution of the changes. |
| HR-59 | Resources-in-use warnings at exit ("69 resources still in use"), in the focused runs and the lead's local runs | many | ChatGPT, lead | not applicable | issue #4 comment 11; state | PARTIAL | COMPLETE (KI-08) | Uninvestigated. |
| HR-60 | Issue #4 not updated after Batch A: the 2026-11-09 merges are not posted there | issue #4 | lead | not applicable | not applicable | UNDOCUMENTED | PARTIAL (noted for the lead) | The lead should post one comment. |
| HR-61 | MP-07, REG-04, REG-05 approved, not implemented; REG-08 investigation; SAV-04 open | none | not applicable | issue #4 comments 9-10 | audit register | COMPLETE | COMPLETE | Waiting for ChatGPT PRs or an owner decision. |
| HR-62 | Draft PR #19 still open; PRs #16-#18, #20, #21 closed as merged when their merge commits reached `wip/b25r2-rev2` | GitHub | lead | not applicable | not applicable | COMPLETE | COMPLETE | Close #19 only after MP-05 merges. |
| HR-63 | Owner's forensics directive; this recovery | records `115268e` | lead, documentation agent | HAG-FORENSICS-01 | directive | COMPLETE | COMPLETE | The independent recovery test is the lead's (directive section 13). |
| HR-64 | The ChatGPT investigation and decision conversations of 2026-11-08 | none | ChatGPT | not applicable | not in GitHub | UNRECOVERABLE | UNRECOVERABLE | Only the GitHub posts survive. |

## 7. Routine activity (grouped; NOT APPLICABLE as separate history)

- **~450 B25R1/B25R2 code commits** on the task branches named above: implementation steps, uid files and floors. Each merged unit's
  history is in its commit message and the register.
- **Temporary single-runner workflows** on the `audit/*` and `feature/*` branches. They were added and then removed in each PR
  (`chore(...): remove temporary ...`): 39 focused runs.
- **CI-only branches** `wip/b25r1-*-ci*`. They were gate-only dispatch copies (`long-sims: a gate-only mode`) with no unique code.
- **145 records commits** on `wip/requirements-control`. These are the records themselves.
- **Scheduled check-ins** (send_later or triggers) in the lead session. These are reading only.

## 8. Register changes for the lead to run on `wip/requirements-control`

**Done 2026-11-09:** the lead ran the commands on `wip/requirements-control` (commit `1b91b71`), and the check reported 1,239 records
with 0 problems. HR-29 and the register half of HR-37 are therefore COMPLETE. HR-37 stays PARTIAL only because the ChatGPT
conversation is unrecoverable (HR-64).

The pre-push hook refuses register edits outside `wip/requirements-control` and staging, so this branch does not change
`requirements.json`. The lead runs the commands in the "Register commands" appendix of this file, then
`python3 tools/check_requirements.py --write`.

## 9. Recovery entry points repaired (this branch)

- [`docs/CURRENT_DEVELOPMENT_STATE.md`](../CURRENT_DEVELOPMENT_STATE.md):
  - a "Current Build 25 state" pointer at the top;
  - a corrected stamp;
  - the worker inventory (directive section 10);
  - the stale "Position" and "Workers and branches" sections are marked superseded, not deleted.
- [`docs/handoffs/CURRENT_SESSION_RECOVERY.md`](../handoffs/CURRENT_SESSION_RECOVERY.md):
  - step 1 names the current branches;
  - a dated correction note.
- [`docs/PROJECT_MEMORY.md`](../PROJECT_MEMORY.md): a "Current Build 25 line" pointer, and this register.
- [`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md): entries for 2026-11-03 to 2026-11-09.
- [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md): KI-06 to KI-14, and dated corrections to stale entries.
- [`docs/decisions/`](../decisions/README.md): seven reconstructed records, and the index.
- `CLAUDE.md` sections 0 and 5a: proposed in a separate commit. The lead decides, and the owner decides on any change to
  BRANCH-POL-01's rule text.

## Register commands

Each command was checked against the tool's options. Run them from the repository root on `wip/requirements-control`.

```sh
# B25R2-BRUSHOFF: approved and integrated
python3 tools/requirements_update.py set B25R2-BRUSHOFF --date 2026-11-08 --disposition APPROVED \
  --field owner_answer="APPROVED (owner directive 2026-11-08 15:12 EST, 'Build 25 audit integration and merge', Phase 1: correct B25R2-BRUSHOFF; docs/directives/2026-11-08_recovered_owner_messages.md)" \
  --why "owner approved the fix 2026-11-08 (recovered directive); disposition was left OPEN"
python3 tools/requirements_update.py set B25R2-BRUSHOFF --date 2026-11-08 --impl INTEGRATED --commit f0a854c \
  --integrated "wip/b25r2-rev2 f0a854c (2026-11-08 23:36 UTC)" --verif "INTEGRATION VERIFIED" \
  --tests "brushoff_empty_plan_test 5/0 (1 script error on the old dialogue.gd); strict Tests 42519022430 passed" --test-commit f0a854c \
  --why "fixed in f0a854c and merged in Batch A (reconstructed 2026-11-09 by the documentation agent)"

# HAG-FORENSICS-01: in progress
python3 tools/requirements_update.py set HAG-FORENSICS-01 --impl "IN DEVELOPMENT" --worker "documentation agent" \
  --branch docs/history-recovery-2026-11 --why "historical recovery under way (coverage register, changelog, decision records)"

# Owner decisions of 2026-11-08: they were not in the register. The id prefix B25-AUD- avoids a clash with
# existing ids (MP-01 is the multiplayer foundation requirement).
S="docs/directives/2026-11-09_overnight_autonomous_development.md; GitHub issue 4 comments of 2026-11-08; audit register on branch docs/build25-audit-register"
python3 tools/requirements_update.py add B25-AUD-LIFE-03 "Sage succession by a qualified healer or apprentice (audit LIFE-03)" --source "$S" --approval "owner, 2026-11-08" --wording "LIFE-03: Qualified healer/apprentice succession is approved." --accept "A qualified successor (healing level 2) takes the sage post; newcomer fallback; save/load" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-LIFE-04 "Widows and widowers may remarry; previous marriage history kept (audit LIFE-04)" --source "$S" --approval "owner, 2026-11-08" --wording "LIFE-04: Widows and widowers may remarry. Preserve previous marriage history and family relationships." --accept "Widowed NPCs and players may court and marry; a living partner always blocks; former spouse kept in history" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-LIFE-05 "Bandit heirs inherit last (audit LIFE-05)" --source "$S" --approval "owner, 2026-11-08" --wording "LIFE-05: Bandit heirs inherit last. Rehabilitation and return to ordinary life are permitted, but criminal history remains." --accept "heir_of skips bandit kin until nobody at home is left" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-PROP-06 "Migrating household: owned property sold atomically, leases surrendered to the manor (audit PROP-06)" --source "docs/directives/2026-11-08_prop06_estate_tenancy_migration.md; $S" --approval "owner, 2026-11-08" --wording "PROP-06: Outright-owned property may be sold before migration, with proceeds retained. Leased property is surrendered to the manor ... Multi-parcel estate sales must be atomic. Existing tenants retain their leases under the new landlord. Failed sales must fully roll back. The Lorekeeper's hut is included when selling owned property." --accept "the directive's 18 cases (prop06_estate_transaction_test)" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-PROP-03 "Surrendered or evicted leased sites, improvements and materials pass to the manor (audit PROP-03)" --source "$S" --approval "owner, 2026-11-08" --wording "Leased property is surrendered to the manor, including improvements and construction materials, without compensation." --accept "eviction path clears the former tenant's unfinished site (prop03_eviction_site_test)" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-MP-05 "Mutual, reciprocal three-tier asset sharing between players (audit MP-05)" --source "$S" --approval "owner, 2026-11-08" --wording "MP-05: Cross-player asset sharing is mutual and reciprocal, requires proposal and acceptance, and defaults to no sharing. ... Either player may revoke sharing. Ownership, sale authority, and demolition authority are not transferred." --accept "host-validated tiers; revocation both ways; real two-device, modified-client, reconnect and UI checks" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-MP-07 "Private records never shared automatically between players (audit MP-07)" --source "$S" --approval "owner, 2026-11-08" --wording "MP-07: Private records are not automatically shared between players. Players learn private information through ordinary gameplay. Asset-sharing agreements do not grant access to private information." --accept "host+two-guest wire-payload privacy tests" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-JUS-04 "Crime affects relatives only once the knowledge reaches them (audit JUS-04)" --source "$S" --approval "owner, 2026-11-08" --wording "JUS-04: Criminal reputation consequences may affect relatives only after the relevant crime information has actually reached them through the game's knowledge systems." --accept "jus04_witness_knowledge_test" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-REG-04 "Couriers travel physically (audit REG-04)" --source "$S" --approval "owner, 2026-11-08" --wording "REG-04: Couriers physically travel." --accept "a living carrier on real road legs; no double delivery; save/load; conservation" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-REG-05 "Migrating households travel physically (audit REG-05)" --source "$S" --approval "owner, 2026-11-08" --wording "REG-05: Migrating households physically travel." --accept "arrival-triggered adoption; one journey system shared with REG-04; PROP-06 settlement where the walk starts" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-REG-07 "Trade intelligence valid at most one eight-day year (audit REG-07)" --source "$S" --approval "owner, 2026-11-08" --wording "REG-07: Trade intelligence remains valid for no longer than one eight-day game year." --accept "intel_test day-boundary cases (stale 4, forget 8, envoy refresh 4)" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-EMP-03 "Count everyone actively seeking work in hiring competition (audit EMP-03)" --source "$S" --approval "owner, 2026-11-08" --wording "EMP-03: Count everyone actively seeking work for hiring-competition purposes." --accept "a test or code reference showing every seeker is counted" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-BIZ-03 "Payroll before owner withdrawals; hiring budgets the whole payroll (audit BIZ-03, Option B)" --source "$S" --approval "owner, 2026-11-08" --wording "BIZ-03: Option B approved. Employee payroll takes priority over owner withdrawals. Hiring affordability must account for existing workforce obligations plus the proposed employee." --accept "biz03_payroll_priority_test" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-BIZ-04 "A migrating household keeps its business money (audit BIZ-04)" --source "$S" --approval "owner, 2026-11-08" --wording "BIZ-04: A living household retains its business money when migrating. Investigate venture tills and ownership transfers to ensure this rule is followed." --accept "biz04_venture_till_migration_test" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-TRD-02 "Merchant earnings recorded net of commission (audit TRD-02)" --source "$S" --approval "owner, 2026-11-08" --wording "TRD-02: Record actual net proceeds rather than gross amounts when calculating the relevant merchant earnings." --accept "trd02_merchant_net_earnings_test" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-INV-04 "Goods left in sold property pass to the purchaser (audit INV-04)" --source "$S" --approval "owner, 2026-11-08" --wording "INV-04: Goods left behind in sold property transfer to the purchaser, subject to existing tenant rights and other established ownership protections." --accept "inv04_stash_handover_test" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-INV-05 "No unapproved rubble-to-dressed-stone conversion (audit INV-05)" --source "$S" --approval "owner, 2026-11-08" --wording "INV-05: Do not permit unapproved conversion of rubble or waste into dressed stone." --accept "inv05_rubble_refund_test" --build 20+ --date 2026-11-08
python3 tools/requirements_update.py add B25-AUD-SAV-02 "Saved economic state preserved through load and continuation (audit SAV-02)" --source "$S" --approval "owner, 2026-11-08" --wording "SAV-02: Preserve saved economic state correctly during loading and continuation." --accept "sav02_day_state_test" --build 20+ --date 2026-11-08

# Implementation and verification evidence (merged on wip/b25r2-rev2; recorded campaigns clean). Not COMPLETE:
# no device or owner playtest, and the register's COMPLETE needs every playtest need done.
for id in B25-AUD-LIFE-03 B25-AUD-LIFE-04; do python3 tools/requirements_update.py set $id --impl INTEGRATED --commit 229f76e --integrated "wip/b25r2-rev2 229f76e (2026-11-09 08:40 UTC)" --verif "INTEGRATION VERIFIED" --tests "strict 42530864510 on 494af9a; recorded campaign 42557922632 (0 CRITICAL, 0 confirmed)" --test-commit 494af9a --why "merged 229f76e; see docs/decisions/B25-AUD-LIFE-03-04.md"; done
python3 tools/requirements_update.py set B25-AUD-PROP-06 --impl INTEGRATED --commit 96b071c --integrated "wip/b25r2-rev2 96b071c (2026-11-09 09:39 UTC)" --verif "INTEGRATION VERIFIED" --tests "prop06_estate_transaction_test 61/0; strict 42587815471 on 96b071c; campaign 42557925404 on a7071aa" --test-commit 96b071c --why "merged 96b071c; see docs/decisions/B25-AUD-PROP-06.md"
for id in B25-AUD-JUS-04 B25-AUD-REG-07; do python3 tools/requirements_update.py set $id --impl INTEGRATED --commit 53a56d3 --integrated "wip/b25r2-rev2 53a56d3 (2026-11-09 11:04 UTC)" --verif "INTEGRATION VERIFIED" --tests "strict 42597744977 on 53a56d3; recorded campaign 42570299554 on 4f1b3c8" --test-commit 53a56d3 --why "merged 53a56d3; see docs/decisions/B25-AUD-JUS04-REG07.md"; done
for id in B25-AUD-LIFE-05 B25-AUD-BIZ-03 B25-AUD-BIZ-04 B25-AUD-TRD-02 B25-AUD-INV-04 B25-AUD-INV-05 B25-AUD-SAV-02 B25-AUD-PROP-03; do python3 tools/requirements_update.py set $id --impl INTEGRATED --commit c9da5db --integrated "wip/b25r2-rev2 c9da5db (2026-11-09 17:25 UTC)" --verif "INTEGRATION VERIFIED" --tests "strict 42607051457 attempt 2 on c9da5db; recorded campaign 42627103286 (0 CRITICAL, 0 confirmed)" --test-commit c9da5db --why "merged c9da5db; see docs/decisions/B25-AUD-BACKLOG-2026-11-09.md"; done
python3 tools/requirements_update.py set B25-AUD-MP-05 --impl "IMPLEMENTED ON TASK BRANCH" --branch wip/b25-mp05-on-dev --commit 242ca83 --verif "TARGETED TESTS PASSED" --tests "full Tests 42636628469 on 242ca83; mp05 24/0; campaign 42664730920 running" --test-commit 242ca83 --why "two cart defects fixed (a898541/2e74066, be307f8/242ca83); security checks on real devices outstanding; docs/decisions/B25-AUD-MP-05.md"
python3 tools/check_requirements.py --write
```

`B25-AUD-EMP-03`, `B25-AUD-MP-07`, `B25-AUD-REG-04` and `B25-AUD-REG-05` stay at NOT STARTED. For EMP-03, the lead's statement that
the code already counts every seeker needs a test or a code citation before the record is marked.
