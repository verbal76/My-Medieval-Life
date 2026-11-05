# Build 25 year-long validation and economic sustainability analysis (2026-11-01)

Register: X20-MERGED-VALIDATION, X20-ECON-SUSTAIN, X20-TELL-GUARD. Owner directives:
`docs/directives/2026-10-31_x20_yearlong_validation_release_readiness.md`,
`docs/directives/2026-10-31_build25_economic_sustainability_analysis.md`.
Published report: https://claude.ai/artifact/DABNtxh28oYx8cWztnoMCQ (same content as `BUILD25_VALIDATION_REPORT.html`).

Commit tested: `ad281dc9431b782582513ef8a083c962b5039b8f` (`wip/expansion20`).

| Run | What |
|---|---|
| 41233948995 | normal settings, seeds 1 and 2 (seed 1 job failed on 1 script error, X20-TELL-GUARD; all 365 days simulated) |
| 41233970504 | economy on (`--market`), seed 1 |
| 41129188776, 41166571846, 41171898332, 41143001791 | earlier year-long runs used as baselines |

How it was made (reproducible; analysis only, nothing in the game changed):
1. The job logs were read with the GitHub job-log API. `parse.py LOG OUT.json` extracts the checkpoints, the bandit and judgment lines and the end totals.
2. The per-checkpoint samples are in each run's `sim.json` artifact. They were read back by the long-sims recover job with a digest step (branch `wip/val-recover`, commit `885723b`, workflow change only, no simulation). `digest.py SAVED_LOG OUT.json` extracts the `DIGEST` lines.
3. `analyze.py` writes `report_data.json`; `build_report.py` (with `charts.py`, `report_head.html`) writes the report.
