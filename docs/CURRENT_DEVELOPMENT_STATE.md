# Current development state

The session handoff (MEM-01, owner 2026-10-20; reshaped by REQ-CTRL-01, owner 2026-10-23). It holds **only
session-specific state**: branches, workers, what is in flight, next actions. It never restates a requirement's status.
That is in the register, `docs/requirements/requirements.json`, and its generated views in `docs/requirements/views/`.

Update it at every checkpoint: after a merge, when a worker starts or stops, before a context handoff (at about 70–75%
context, where measurable) and before a session ends. The previous long-form state file is archived in
`docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-23.md` (history only).

**Updated:** 2026-10-23 (Build 18 delivered as a private draft; Expansions 19-21 progress directive: docs/directives/2026-10-23_expansions_19_20_21_progress.md).

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
| `wip/build18` | `239bdff` (2026-10-23; Build 18 draft release from `61ec528`) | Build 18 integration; + credit parity, ECON-P3 business money, the capability profile, DP-15 sage evidence, X18-SIM report, SET-D, farming audit and church-field volunteering + stone corrections, NPC competition, player businesses |
| `wip/build17` | `dfec7ec` | Build 17, frozen (private playtest draft from code `cd7439c`) |
| `wip/expansion19-preparation` | `c2ece16` | Build 19 judgment prototype, switched off, isolated (PROS-01); synced with Build 18 (SYNC-18, merge c2ece16: gate identical, judgment and shared suites pass) |
| `wip/expansion20-preparation`, `wip/expansion21-preparation` | `d82f173`, `0eeb3df` | documents only; Builds 20 and 21 not authorized |
| `wip/multiplayer` | `d18d7d1` | MP-01, excluded from Build 18; never merge without the owner |
| `main` | | changes only when the owner merges |

## Workers in flight

Each is a record in IN DEVELOPMENT; the validator requires it to be named here.

| Record | Worker | Branch | Started from | Notes |
|---|---|---|---|---|
| PROS-19 | X19 sync worker (Sonnet subagent) | `wip/expansion19-preparation` (worktree `.claude/worktrees/agent-a6cffdef98c095994`) | c2ece16 | Build 18 merged (c2ece16); X19-Q-TIMING done (3f89816); rule answers done (2456294: SJD-Q05, Q09, X19-ASSAULT; Q12, HARMED, CRT12 already matched; Q04 partial). Now X19-GUARD (the live friend's waiver becomes a reduction), then X19-REGARD; X19-DECAY stays provisional |

Expansions 20 and 21: implementation not authorized (register `builds` map: OD-30, OD-LE-01); no worker.
Decision packet for starting them: `docs/design/EXPANSIONS_20_21_DECISION_PACKET.md` (2026-10-23; awaiting the owner).

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
3. DONE: long-sims run 39904513181 on 61ec528, seeds 1-4: no leak, FATAL or script error; before/after comparison and a
   probe showing the alms reach every short household (LONG_RUNS_365_ALMS.md on wip/build18, ecd91d4); decisions D10-D11.
4. DONE: Build 18 released as a private draft (run 39935635926 on 61ec528; packet BUILD_18_PACKET.md on wip/build18,
   239bdff): three packages downloaded back, checksums match, audio per platform checked, Linux binary launched.
5. NEXT: the owner's device playtest (REL18-DEVICE); public publication only with the owner's approval. The morning
   report was given in the session.
6. Expansions directive (2026-10-23): Build 18 merged into `wip/expansion19-preparation` (c2ece16, reviewed); the worker is on
   X19-GUARD, then X19-REGARD. Done: X19-Q-TIMING (3f89816), the rule answers (2456294). Open number questions for the
   owner: X19-GOSSIP-FLOOR, X19-RUNNERUP.
   Expansions 20 and 21: decision packet given to the owner; no work until answered.
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
