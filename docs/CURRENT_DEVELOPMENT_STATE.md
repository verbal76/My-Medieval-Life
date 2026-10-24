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
| PROS-19, X19-FOUND | none (round complete) | `wip/expansion19-preparation` | c756211 | foundations round merged and verified (ten suites, gate identical, perf); waits on the owner's numbers and formulas |
| E20-P1 | X20 foundation worker (done) | `wip/expansion20-preparation` | 4d9bc05 | reservation record, event record, actor resolver built, off, tested, gate identical; waits on the owner's architecture review and OD-LE answers |
| P21-01 | X21 foundation worker (done) | `wip/expansion21-preparation` | 8ac88f5 | civic records built, off, tested, gate identical; P21-00 and P21-02 done (64317eb) |
| E22-P1, E23-BANA | lead (done) | staging (documents) | - | audit written: docs/design/EXPANSIONS_22_23_AUDIT.md; waits on the owner's review; no implementation |
| XAUDIT-01 | lead (done) | staging (documents) | - | report docs/design/CROSS_EXPANSION_PRESERVATION_AUDIT.md; awaits the owner's review; findings D1 (judgment save bypass) and D2 (economy save drop) are defects on the prospective branches, unfixed by instruction |
| FIX-D1D2, FIX-D3 | repair workers (done) | `wip/expansion19-preparation` (fd99591 D1, 3ec38d2 D3), `wip/expansion20-preparation` (af62948 D2) | - | done and reported 2026-10-23; branches stay separate until the owner approves the integration plan |
| ID-01 | identity worker 2 (done) | `wip/foundation-identity` | 84d1880 | option B done; gate divergences explained (docs/design/IDENTITY_GATE_ANALYSIS.md); waits on ID-D3 (candidate baseline); then merge into wip/recorder |
| RECON-01 | reconciliation worker (done) | `wip/expansion19-preparation` 4a0459f, `wip/expansion20-preparation` 1befd0e | - | one tolerance calculation; reservations recognise contract holds; gate identical |
| REC-19 | recorder worker (done); lead | `wip/recorder` | 2d5d49c | identity merged, D3 instrumentation done (824e32c); FIX-RECF1/SIM-F9 merged by the lead (2d5d49c); combined gate running; next: into the Build 19 integration branch |
| FIX-RECF1 | lead (done) | `wip/fix-recf1` merged into `wip/recorder` 2d5d49c | b113f73 | integrated; bandit starvation differences unattributed until the recorder shows causes (SIM-F4 open) |
| FAM-SAC-01 | family worker (done) | `wip/expansion19-preparation` | fff48a4 | built behind the switch, tests pass, gate identical; danger behaviour answered by the owner (shield and fetch help), added by the X19 completion worker |
| X19-SCOPE | lead (done) | `wip/build19` | 2f72ec3 (packet 42c33e0) | Build 19 private draft released (run 40044931601), packages checked; complete as the development milestone (owner 2026-10-24); public publication only with the owner's approval |
| MP-MASTER | **ON HOLD** (owner, 2026-10-24: Upwardly takes priority); no agent running | `wip/multiplayer-b19` (worktree `.claude/worktrees/mp`) | 2b92fa8 = G2 complete (Batches A1, A2, B, C done; G0, G1, G2 passed; lead-verified) | Build-ready as Build 21 (the Build 21 tester notes are on the branch); do NOT build or publish without the owner's explicit approval. On resume: run Godot `--import` once (new NetSync class), read the branch's Batch C notes (docs/multiplayer, BATCH_C), then Batch D only after owner approval. Open owner decisions: MP-Q-PLAYER-CHILDREN, GP-INTERIOR-WALLS, GP-BANDIT-CAMP-ART, SIM-GATE-01 thresholds. `wip/mp-batch-c-snapshot` (8897246) is a superseded safety copy. |
| SIM-GATE-01 | done; merged | `wip/multiplayer-b19` 95249b7 | gate PASS locally on the merge | Active for the next release from this branch; thresholds await the owner |
| REC-DIAG | lead | recorder archives (scratchpad), read-only runs of `wip/recorder` | 94b1304 | simulation-first analysis (docs/directives/2026-10-23_simulation_first_diagnostics.md); findings in docs/design/SIM_FINDINGS.md |

Expansion 20: phase 1 authorized 2026-10-23 (docs/directives/2026-10-23_expansion20_phase1_authorization.md); Expansion 21: phase 1 authorized 2026-10-23 (docs/directives/2026-10-23_expansion21_phase1_authorization.md).
Alignment report and capability matrices: `docs/design/EXPANSIONS_19_21_ALIGNMENT.md` (2026-10-23). No worker is running; every next step waits on the owner's answers.

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
6. X19 foundations round: DONE (c756211; report given 2026-10-23).
7. Expansions directive (2026-10-23): Build 18 merged into `wip/expansion19-preparation` (c2ece16, reviewed); the worker is on
   nothing more until the owner answers the numbers (then 365-day calibration off vs on). Done: hooks (577821d), event feeds (e8d4122), X19-Q-TIMING (3f89816), the rule answers (2456294), X19-GUARD (949b5b9),
   X19-REGARD (46b46e5), SJD-Q03/Q13 (ca2e9ba). Open number questions for the owner: X19-GOSSIP-FLOOR, X19-RUNNERUP,
   X19-TRUST-RATES, X19-PERSONALITY, X19-EVENT-Q; X19-DECAY awaits the calendar explanation (given 2026-10-23 in the session).
   Expansions 20 and 21: decision packet given to the owner; no work until answered.
8. **Build 19 complete scope (owner 2026-10-23, X19-SCOPE, `docs/directives/2026-10-23_x19_complete_release_scope.md`): the
   priority.** All Expansion 19 numbers are now answered (`docs/directives/2026-10-23_owner_answers_x19_release_decisions.md`,
   packet `docs/design/X19_RELEASE_DECISIONS.md`; spillover reach: extended kin through second cousins at falling, provisional weights, per the owner's clarification `docs/directives/2026-10-23_owner_clarifications_famrep_simf4.md`). Plan:
   (a) FAM-SAC-01 worker lands; (b) a completion worker on `wip/expansion19-preparation` sets the approved numbers, switches
   personality, family reputation, lies (X19-MISINFO), family stories (X19-STORY-LIFE), stubbornness and self-defence live,
   judgment on by default; (c) integrate with identity (84d1880), FIX-RECF1/SIM-F9 (b113f73) and the recorder (off in public
   builds) on one Build 19 integration branch; (d) targeted integration tests, conservation, combined first-divergence check
   on both seeds and ONE proposed baseline; (e) present Build 19 for release authorization (never publish automatically).
   The mayoral term (four game years) is settled and not reopened.
9. **Expansions 25 and 26 (owner 2026-10-23, design only, no code):** packets
   `docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md` (WEATHER-01) and `docs/design/EXPANSION26_CREATURES_AND_HEROES.md`
   (PET-01, MON-01, B14-09, FR-01); split per `docs/directives/2026-10-23_split_expansions_25_26.md`; open questions in each
   packet's section 6 / 5. They never delay Build 19.
10. **Roadmap reprioritization (owner 2026-10-24, ROAD-03, planning only):** order 20, 21, 23, 22, 24, 25, 26, 27 (to verify);
   review `docs/design/ROADMAP_20_27_PRIORITY.md`; questions ROAD-Q1..Q5. No expansion implementation until separately
   authorized. Build 19 frozen pending the owner's playtest.
11. **Multiplayer next (owner 2026-10-24, MP-MASTER, `docs/directives/2026-10-24_master_multiplayer_directive.md`):** sequence
   Build 19 acceptance → full multiplayer → Expansion 20. Preparation only now (assessment, plan, decisions; MP-D1 open);
   implementation after Build 19's owner acceptance and explicit authorization. Prototype `wip/multiplayer` d18d7d1 preserved;
   its notes and the 2026-10-21 audit in `docs/multiplayer/`.
   Architecture approved in principle; MP-D1..D8 decided 2026-10-24 (MP-ARCH, MP-INET); plan with gates G0-G10 in
   `docs/multiplayer/MULTIPLAYER_PREPARATION.md`. Report multiplayer's stage in every status report until owner acceptance.
12. **Gameplay and Controls Polish (owner 2026-10-24, GP-POLISH and eight children):** P1 (anvil, Android pickaxe animation,
   Android action layout) right after multiplayer Batch A1; P2 (overhead progress bar, joystick, continuous harvesting,
   lockpicking minigame, input consistency) after Batch A; before Expansion 20 (`docs/gameplay_polish/SCHEDULE.md`).
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
