# Current development state

The session handoff (MEM-01, owner 2026-10-20; reshaped by REQ-CTRL-01, owner 2026-10-23). It holds **only
session-specific state**: branches, workers, what is in flight, next actions. It never restates a requirement's status.
That is in the register, `docs/requirements/requirements.json`, and its generated views in `docs/requirements/views/`.

Update it at every checkpoint: after a merge, when a worker starts or stops, before a context handoff (at about 70–75%
context, where measurable) and before a session ends. The previous long-form state file is archived in
`docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-23.md` (history only).

**Updated:** 2026-10-23 night (owner asleep; overnight Build 18 completion and private release authorized: docs/directives/2026-10-23_build18_overnight_completion_release.md).

## Read first (after a compaction or in a new session)

1. `CLAUDE.md` section 0. Then this file.
2. `docs/requirements/views/STATUS.md` (where each build stands), `BUILD_18.md` (the active build), `DECISIONS.md` (open
   owner decisions), `QUEUES.md` (workers, untested work, playtest queue).
3. The record of any task you resume, in `docs/requirements/requirements.json`; the procedure in
   `docs/requirements/SCHEMA.md`.

Never reconstruct state from a conversation summary: these files are the record.

## Branches

| Branch | Head | Role |
|---|---|---|
| `staging/my-medieval-life` | see `git log origin/staging/my-medieval-life -1` | records: the only branch where the register is edited |
| `wip/build18` | `61ec528` (2026-10-23) | Build 18 integration; + credit parity, ECON-P3 business money, the capability profile, DP-15 sage evidence, X18-SIM report, SET-D, farming audit and church-field volunteering + stone corrections, NPC competition, player businesses |
| `wip/build17` | `dfec7ec` | Build 17, frozen (private playtest draft from code `cd7439c`) |
| `wip/expansion19-preparation` | `c4b10e4` | Build 19 judgment prototype, switched off, isolated (PROS-01); synced with Build 17 only |
| `wip/expansion20-preparation`, `wip/expansion21-preparation` | `d82f173`, `0eeb3df` | documents only; Builds 20 and 21 not authorized |
| `wip/multiplayer` | `d18d7d1` | MP-01, excluded from Build 18; never merge without the owner |
| `main` | | changes only when the owner merges |

## Workers in flight

Each is a record in IN DEVELOPMENT; the validator requires it to be named here.

None in flight (chapel audit done: docs/build18/CHAPEL_AUDIT.md).

### Running processes (never restart or cancel; SIM-02)

None (the 365-day runs, run 39874405723, finished 02:04 UTC).

On their reports:
1. Review the work.
2. Merge it into `wip/build18`.
3. Run targeted integration and conservation checks on the merge commit (the suites the change touches, conservation runs); not broad suites without a specific reason (owner 2026-10-23, MSW-01). For the regions merge: the chapel and settlements share the settlement holdings script and the economy ledger.
4. Update the records: INTEGRATED, `test_commit`.
5. Regenerate the views.

## Next actions (lead)

Overnight plan (owner authorization 2026-10-23; decisions made on the owner's behalf go in
`OWNER_REVIEW_DECISIONS.md` (wip/build18, folder docs, build18), D1 onward):
1. DONE: CHAPEL-R2 alms implemented on `wip/build18` (local commit 5bdecb7: `chapel.gd::alms`, `household_shortfall`,
   `chapel_test::test_alms`, wiki, INT-404, DECISIONS, owner-review log), tester notes BUILD_18_TESTER_NOTES.md (wip/build18, release docs).
2. DONE on `wip/build18` 61ec528 (pushed): all 85 suites pass; determinism gate PASS, identical to the baseline (no alms are
   paid in the first 30 days: households still hold enough); tester notes committed.
3. RUNNING: long-sims run 39904513181, 365 days, seeds 1-4, on 61ec528 (dispatched 05:12 UTC; pre-alms runs took 74-133
   min). Never cancel or redispatch (SIM-02). When done: compare (compare with the pre-alms runs in
   LONG_RUNS_365.md (wip/build18); read checkpoints from the job log, artifacts are blocked; the recover_run mode exists).
4. THEN, only if every gate passes: release.yml on `wip/build18`, visibility private (draft), allow_temporary_key true (no
   signing secrets), build_number 18; verify the three artifacts and the music fetch step; write
   a BUILD_18_PACKET.md in the release docs; morning report to the owner (format in the directive, section 9).
Do not publish publicly; do not reopen settled decisions; no open-ended repair campaign.

## Waiting on the owner

Every open decision is in `docs/requirements/views/DECISIONS.md`. The decision package B18-DP-01..14 was answered 2026-10-23 (`docs/directives/2026-10-23_build18_decision_package_answers.md`); B18-DP-15 and DP-16 were answered (`docs/directives/2026-10-23_dp15_dp16_con02_empperm.md`). In this session:
- the calendar question: X19-DECAY held as PROVISIONAL pending the owner's view of the 8-day year;
- the stone values (STONE-D1, STONE-D2);
- Build 18 target (owner 2026-10-23, `docs/directives/2026-10-23_reg_demo_d1_and_build18_target.md`): playable within five hours; punch list fixed; blockers to the owner promptly; REG-CIRC-D1 deferred until REG-EVAL-01;
- Build 18 packaging gate (REL18-PACKAGE): no test package until every Build 18 punch-list item is closed or accepted as permanently blocked;
- chapel review, non-blocking: CHAPEL-R1..R5 (player volunteering, offerings funding wages, old-save plants, ore layout, chapel art); the chapel's economic values are provisional working values;
- Builds 20 and 21 authorization.

## Waiting (sequenced)

- REL18 release runs (365 days per seed, 100-day read), REG-EVAL-01, WDR-004-C and SET-C verification: on the final Build 18 code.
