# Simulation baseline replaced for the Expansion 20 integration (2026-10-31)

Owner directives: `docs/directives/2026-10-30_x20_background_development.md` (s.2, one baseline simulation on the merged
commit), `docs/directives/2026-10-30_b24_review_remediation_x20_integration.md`; contract 5 of
`docs/handoffs/PARALLEL_WORK_2026-10-30.md` (the lead replaces the baseline once per integration, with evidence).

## What changed in shipped behaviour

`wip/expansion20` gained, with the Living Economy switch still off:

- settlement-to-settlement food trade through the transaction authority (X20-SETTLE-FOOD);
- Build 24 review fixes 1-3: idle settlement traders close; leavers keep their tills, stores and stall takings;
- review fixes 6-7: stall commission recorded at settlement; tills go to the previous holder on any holder change;
- trader reopening (X20-SETTLE-REOPEN).

LE-03 and LE-04 village behaviour stays behind the switch. Their own G0 run, 41135548780, was identical to the old baseline.

## Evidence

| Run | Commit | Where | Seed 1 day 30 | Seed 2 day 30 |
|---|---|---|---|---|
| Old baseline | 4611d86 line | committed | `c24e8660…` | `45fd9acb…` |
| Actions 41142767484 (recorded, archive checked) | 8bbdcfb | GitHub | `d4a1d71d567eec3cde55d794f8a43351` | `40a3f050bcea4260c85d79e6b49c4da5` |
| Local `tools/sim_gate.py` | 8bbdcfb | container | `d4a1d71d…` (identical) | `40a3f050…` (identical) |
| Local `sim_gate.py --write` (this baseline) | ed6360f | container | `d4a1d71d…` | `40a3f050…` |
| Local `sim_gate.py` re-check | ed6360f | container | PASS, identical | PASS, identical |

The fingerprints are identical across the GitHub runner and the container, and between two local runs, so the run is deterministic. `ed6360f`, which adds trader reopening, has the same day-30 state as `8bbdcfb`. Reopening needs two weeks of unmet demand after a closure, and no settlement reaches that within 30 days. The 60-day evidence for reopening is run 41139763023.

## Day 30, 8bbdcfb and ed6360f (economy off)

| | Seed 1 | Seed 2 |
|---|---|---|
| Village coins, day 0 → 30 | 3009 → 3733 | 2966 → 3766 |
| Coin leak / item leaks / holder mismatch / coin-source mismatch | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| Alive (start 104), starved | 117, 0 | 111, 0 |
| Net coins from the settlements (coin sources) | 724 | 800 |
| Caravans | 15 | 15 |
| Settlement traders closed when nobody worked them | Netherton, Garton, Bourton | Netherton, Garton, Bourton |
| Migration | 1 in (marriage) | 2 out, 1 in (marriage) |
| Contract, quest and manor-wage reserves at the end | 0 | 0 |
| Recorder archive check (`tools/recorder_archive.py`) | ok | ok |
| Crashes, exceptions, stalls | none (Godot's leak warnings at exit only) | none |

Against the old baseline, village coins at day 30 are 3964 → 3733 on seed 1 and 3825 → 3766 on seed 2, and the treasury is 17 → 6 and 8 → 1. That is redistribution, not loss: the coin totals and every holder reconcile exactly (`currency.holders_mismatch` 0, leak 0). The coins sit with settlement councils, which receive a closed trader's till, and in the food trade's flows. X20-TRADER-PAY-INV reconciles where the coins went in detail.

Save and load: the merge suites (save_transfer_test, le06 fixtures on `wip/x20-le06`) and X20-MP-ECON-INTEGRITY's host-restore scenarios reload the books exactly.
