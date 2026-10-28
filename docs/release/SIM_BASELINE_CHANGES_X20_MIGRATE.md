# Simulation baseline: changes from free migration (REG-X20-D1) and the Expansion 20 foundation merge

Evidence for replacing `docs/release/sim_baseline.json` (previous one kept as `sim_baseline_pre_x20_migrate.json`).

## What changed the simulation

- **Free migration** (owner decision REG-X20-D1, 2026-10-27; `wip/x20-migrate` 8df2f59): the sole-worker and last-household
  retention rules are removed and each settlement household waits its own patience before leaving for hunger
  (`move_patience_days_max` 4, provisional). This is the only change that moves the 30-day checkpoints.
- **Visible sword** (GP-SWORD-VIS, `wip/x20-sword` 8fd01fa) and **till ownership and REC-DIAG** (`wip/x20-foundation` 3a6eee8):
  no effect on any checkpoint (identical fingerprints, below).

## The runs (seeds 1 and 2, 30 days, checkpoints 10 and 30, shipped switches)

| Run | Code | Where | Result |
|---|---|---|---|
| Free migration alone | 8df2f59 | local sim_gate | 14 differences, all at day 30; day 10 identical |
| Migration + sword | 4d4f4a1 | local sim_gate | identical to the migration-alone run (every value) |
| Migration + sword + foundation | 5c303be | GitHub Actions long-sims run 40622479865 | day-30 fingerprints identical to the runs above (seed 1 `c24e8660...`, seed 2 `45fd9acb...`); leak 0, holders mismatch 0, item leaks none at every checkpoint |
| Baseline recorded | merge head | local `sim_gate --write` | written to `sim_baseline.json` |

| Seed | Day 30 | Old baseline | New |
|---|---|---|---|
| 1 | alive | 111 | 113 |
| 1 | currency | 4251 | 3964 |
| 1 | treasury | 1 | 17 |
| 2 | alive | 117 | 111 |
| 2 | currency | 3918 | 3825 |
| 2 | treasury | 16 | 8 |

Conservation intact at every checkpoint of every run (currency leak 0, no item leaks). The differences are outcomes of a
different history (households now free to leave), measured, not judged (WDR-022).

Two local attempts on the merged code were killed by container restarts; the GitHub Actions run replaced them, so no result
here depends on a run that did not finish.
