# Current development state

The session handoff (MEM-01, owner 2026-10-20; reshaped by REQ-CTRL-01, owner 2026-10-23). It holds **only
session-specific state**: branches, workers, what is in flight, next actions. It never restates a requirement's status.
That is in the register, `docs/requirements/requirements.json`, and its generated views in `docs/requirements/views/`.

Update it at every checkpoint: after a merge, when a worker starts or stops, before a context handoff (at about 70–75%
context, where measurable) and before a session ends. The previous long-form state file is archived in
`docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-23.md` (history only).

**Updated:** 2026-10-23 (`wip/build18` b2f5c5d: pre-package verification under way; determinism gate, Build 17 save, all 83 suites and the wiki gate done).

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
| `wip/build18` | `5181dc7` (2026-10-23) | Build 18 integration; + credit parity, ECON-P3 business money, the capability profile, DP-15 sage evidence, X18-SIM report, SET-D, farming audit and church-field volunteering + stone corrections, NPC competition, player businesses |
| `wip/build17` | `dfec7ec` | Build 17, frozen (private playtest draft from code `cd7439c`) |
| `wip/expansion19-preparation` | `c4b10e4` | Build 19 judgment prototype, switched off, isolated (PROS-01); synced with Build 17 only |
| `wip/expansion20-preparation`, `wip/expansion21-preparation` | `d82f173`, `0eeb3df` | documents only; Builds 20 and 21 not authorized |
| `wip/multiplayer` | `d18d7d1` | MP-01, excluded from Build 18; never merge without the owner |
| `main` | | changes only when the owner merges |

## Workers in flight

Each is a record in IN DEVELOPMENT; the validator requires it to be named here.

One worker: the old-save fixes (CHAPEL-R3, CHAPEL-R4 and the ROOMS-18 plant ids; REL18-SAVE known defects) on `wip/b18-savefix` from `wip/build18` 5181dc7; load path and records only, new-world generation unchanged (the determinism gate must still pass).

### Running processes (never restart or cancel; SIM-02)

| What | Where | Code | Started |
|---|---|---|---|
| Build 18 365-day runs, seeds 1-4, checkpoints every 10 days (REL18-LONGRUN, SET-C, WDR-004-C; day 100 read from them) | GitHub Actions long-sims run 39874405723 | `wip/build18` 9a86f5c | 2026-10-22 23:50 UTC |

On their reports:
1. Review the work.
2. Merge it into `wip/build18`.
3. Run targeted integration and conservation checks on the merge commit (the suites the change touches, conservation runs); not broad suites without a specific reason (owner 2026-10-23, MSW-01). For the regions merge: the chapel and settlements share the settlement holdings script and the economy ledger.
4. Update the records: INTEGRATED, `test_commit`.
5. Regenerate the views.

## Next actions (lead)

1. Implementation is complete except owner items (B18-DP-17 STONECUT-R1 blocks WDR-002-C; DP-18, DP-19 non-blocking).
   Pre-package verification done: REL18-DET, REL18-SAVE, REL18-SUITES, REL18-WIKI. Still to do: read the 365-day runs
   (REL18-LONGRUN, SET-C, the 100-day read), WDR-004-C scarcity audit and REG-EVAL-01 against the preserved baseline
   (`docs/investigations/evidence_2026-10-23_regional/`) from those runs, then the three-platform candidate
   export (REL18-EXPORT) for the owner's device playtest; no distributable published without the owner. SET-D's
   multi-generation check stays outstanding unless a run with a sufficient horizon is shown (B18-DP-05).
2. The approved, unblocked Build 18 work in `docs/requirements/views/BUILD_18.md` ("Open, ready" and "not started" with
   design SPECIFIED). The audit's highest-value items:
   - wiring the couriers, formal contracts and Law notary (X18-Q12, X18-Q12-BOOTH, X18-Q12-POST, X18-Q13, LAW-SKILL);
   - ECON-P3, DVW-B5, DVW-B3-FEAST;
   - now unblocked by the regions merge: TRADE-CREDIT, MIGRATE-18, DVW-B3-LUX (couriers still use the old SettlementLedger parties).
3. Human reviews flagged by the reconciliation (`docs/requirements/RECONCILIATION_2026-10-23.md`, "Needs review").
4. The Build 18 release gate (REL18-*) only when the work is integrated; no distributable without the owner.

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
