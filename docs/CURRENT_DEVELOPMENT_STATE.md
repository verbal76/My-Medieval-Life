# Current development state — active handoff

**Updated 2026-10-27 (Build 23 released as a private draft).** Fetch current heads before acting. The previous handoff is preserved at `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_pre_2026-10-27_authority_cleanup.md` as an archived audit snapshot, **not active tasks**.

## Current baseline and mandatory release gate

- **Build 23 (Expansion 20)**: private three-platform draft, release 425699977 (tag `build-23`) from `c79b12c` (`wip/x20-final`; `wip/expansion20` advanced to it), run `40526826846` (sim-gate passed, then exports). Verified: checksums, the permanent signing certificate (same as Builds 21-22), package and versionCode 23, Windows and Linux packages, Linux start. Tester notes: `BUILD_23_TESTER_NOTES.md` in `docs/release` on `wip/expansion20`. **Not device-checked**: phone install over Build 22, Windows, controller, the nine host/guest multiplayer pairs.
- **Build 22**: earlier private three-platform draft (`wip/build22` `b7e1c91`, run `40398771937`, 2026-10-26). Frozen, not reopened.
- **Expansion 20**: authorized in development on `wip/expansion20` (last observed `0dc0014`). LE-01 foundation with off switch, Android UI and Messages journal, and R1–R4 of Build 19 recovery have been integrated. Remaining recovery verification and LE-02–LE-07 are not finished, regardless of prior draft documents.
- **Aspirations R5**: merged into `wip/expansion20` at `3601211` (merge of `wip/x20-r5` `2cc0007`) (six domains including social standing; survival pressure from real household harm only; family protections; Q8=A proposal acceptance behind the flag, hard limits first; all switches off). **Combined validation PASSED on `3601211`** (29 suites 0 failures, G0 identical): **`3601211` is the verified integration baseline for MP-INTERACT-01** (frozen; `wip/expansion20` stays there until the multiplayer merge). Follow-up: extend proposal weighing to player suitors (engineering, D39 and Rule 012).
- **Multiplayer MP-INTERACT-01**: isolated `wip/x20-mp-interact` (`0ce4c9e` at last observation), implemented and targeted UI/network tests, **NOT YET INTEGRATED**. Two open owner questions MP-INTERACT-Q1/Q2 remain. Merge **LAST** onto the frozen combined X20 baseline and validate on Android/Windows/Linux with actual host/guest, input methods and real device gaps correctly identified.
- **Release blocker satisfied (2026-10-27):** MP-INTERACT-01 was merged last (`87b69ab`) and validated before Build 23 was built. Publishing beyond a private draft remains separately controlled; Build 22 stays frozen.
- **Requirements**: owner reconciled 39 decisions on staging `5484ce1`; DCR-01 continuity added at `866af5c`. At this recorded point: 2 open multiplayer questions and 2 provisional (armour/identity); read latest register for counts. Future decisions are design only, not blanket work permission.

- **Other records in development** (the register validator requires them named here): ID-01 (identity, `wip/foundation-identity`; waits on ID-D3's same-commit audit) and REC-DIAG (simulation diagnostics; continues as part of R6 measurement).

## X20-FINAL: final validation, recorder modernization and automatic release (owner, 2026-10-27)

`docs/directives/2026-10-27_x20_final_validation_recorder_release.md` supersedes the need for another release approval: when every
technical check is clean, build and release Android, Windows and Linux together from one verified commit, with the existing visibility
(private draft) and the permanent signing key. Integration branch `wip/x20-final` (worktree `.claude/worktrees/x20-final`):
MP-INTERACT-01 merged at `87b69ab` onto the verified baseline `3601211`: 26 suites 0 failures, G0 identical; `wip/expansion20` advanced to `87b69ab`. Plan, in the owner's order:
(1) validate 87b69ab, then the remaining X20 release fixes (SIM-F2 chisel, SIM-F3 bandit stalk, player/NPC proposal equality);
(2) coverage audit of Expansions 18-20; (3) recorder and scenario updates; (4) black-box campaigns (normal, stress, social,
a few long runs on GitHub Actions, multiplayer 1+2 and 1+3); (5) independent archive analysis; (6) fix genuine defects;
(7) final clean gate on the release commit; (8) release; (9) consolidated report. No overlapping workers on the same expensive run.
Workers from 87b69ab (2026-10-27): M on `wip/x20-fixes` (SIM-F2, SIM-F3, player/NPC proposal equality; owns npc_brain.gd and proposal code); N on `wip/x20-recorder` (coverage matrix, recorder instrumentation, scenarios, analysis tooling; owns the recorder and sim tools); O on `wip/x20-mptest` (1+2 and 1+3 multiplayer scenarios, host/guest consistency, device matrix; owns the net test harness). All three merged on `wip/x20-final` at `eaf6652` (recorder 37c7298, multiplayer scenarios 720016a, fixes f736044); single-player baseline replaced for SIM-F2 with evidence (old kept as sim_baseline_pre_x20_fixes.json; DECISIONS 2026-10-27). **Validated on eaf6652:** 35 suites and the Python tests 0 failures; full simulation gate PASS (0 blocking, baseline identical, determinism identical with shipped and X20 switches); Actions long runs 40478714284 and 40478725139 passed (no leaks, archives complete). Known minor: 2 NPC-hours on a just-built fence cell; a loaded save with the X20 switches fills 74 default keys. **Open:** off-map settlement hunger deaths in both 80-day runs (bourton, netherton, garton, higham), being classified (investigation worker, worktree x20-reginv); recorded multiplayer run running. Next: recorded multiplayer black-box (MML_RECORD on net_mp4), archive analysis against the owner's 15 checks, defect fixes, final gate, release. A container restart (2026-10-27, third that day) stopped all three; their uncommitted work survived in their worktrees and they were resumed with orders to commit WIP snapshots first (recorder already at a7b5778).

- **Build 23 released (2026-10-27):** release.yml run 40526826846 on `c79b12c` completed (sim-gate 15:01-16:03, build 16:03-16:15); private draft 425699977. X20-FINAL and MP-INTERACT-01 are RELEASE CANDIDATE pending the owner's device checks.

## Next actions (current work only)

**Owner 2026-10-28 (`docs/directives/2026-10-28_x20_checkpoint_build_and_pause.md`, X20-CHECKPOINT): produce the Build 24 private
checkpoint from `wip/expansion20`, write the recovery handoff, then PAUSE all Medieval development (Upwardly is the priority).** No
Expansion 21, no LE-03, no new workers, never public. In progress by the lead: Build 24 validation and packaging, then the
recovery handoff `docs/handoffs/X20_RECOVERY_HANDOFF.md` (written 2026-10-28: all remaining Expansion 20 work, branches, gates). X20-COMPLETE is suspended after the checkpoint. TILL-D1 done (X20-TILL-KEEP); LE-02 merged (`e8cc44b`).

## Sources

Live statuses: `docs/requirements/requirements.json`, `docs/requirements/views/`; binding rules: `CLAUDE.md`, `docs/WORLD_DESIGN_RULES.md`, applicable owner directives (2026-10-27 multiplayer, aspirations, 39 decisions, DCR-01); current roadmap: `docs/EXPANSION_ROADMAP.md` active header. All earlier content in `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_pre_2026-10-27_authority_cleanup.md` is historical only.
