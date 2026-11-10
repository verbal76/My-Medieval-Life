# Testing runs on GitHub Actions (default from 2026-11-10)

Owner directive 2026-11-10 (`docs/directives/2026-11-10_github_actions_testing.md`, register B25-CI-ACTIONS-01): Claude develops
and investigates; GitHub Actions executes the tests; Claude reviews the evidence; verified changes become eligible for integration.
Local runs are for quick feedback while writing a change (one focused test, a few game days) and for what CI cannot do.
This extends `docs/ci/CI_ARCHITECTURE_B25R1.md` (shards, gate split, chained campaigns), which stays valid.

## Which workflow for which test

| Need | Workflow and inputs | Runners | Wall clock (measured) |
|---|---|---|---|
| Full regression (integration gate for a branch) | `tests.yml`, no inputs | 12 shards + report | 49 min (42867796686) |
| One subsystem | `tests.yml` `group`: save, determinism, economy, population, multiplayer, recorder, justice (`tools/ci_groups.json`) | 1 | size of the group |
| Named suites (a new or fixed test) | `tests.yml` `only`: suite paths | 1 | a few minutes |
| Simulation gate (33-finding baseline comparison, determinism) | `long-sims.yml` `gate: true` | 5 parts + judge | 26 min (42867803221) |
| 365-day recorded campaign | `long-sims.yml` `flight: true`, `seeds`, `days 365`, `every 10`, `record true`, optional `sim_args` (incl. `--perturb N` on experiment branches) | 1 chained job per segment per seed | 3 h 20 min for seeds 1-2 (42832338970) |
| Year-long comparison runs (no recorder) | `long-sims.yml` `seeds`, `days`, `set`/`variants` | 1 per seed and variant | 41-84 min a seed |
| Three-platform build and release qualification | `release.yml` (owner-authorized only) | Android, Windows, Linux + gate | - |

Independent parts run in parallel and fail separately: a red shard is re-run alone (`rerun_failed_jobs`) or with `only`, never by
re-running the whole set. A targeted run (`only` or `group`) uses one runner and skips the full run's Python checks and 10-day
economy run, which belong to the full run.

## Cost

The repository is public: standard GitHub-hosted runners bill 0 minutes (measured: billable 0 ms on 42867796686, 42867803221,
42832338970). The limits that matter are wall clock and concurrent jobs (20 on the free plan; more queue). Rules:
- Targeted runs (`only`, `group`) for small changes; the full run and the gate before a merge; campaigns for simulation-affecting
  changes at integration gates and for owner-approved investigations.
- Reuse valid evidence: a result stays valid while the commit it ran on is unchanged in the parts it covers.
- Never cancel a run whose evidence is still needed; cancel only superseded runs that no record depends on.
- Godot is cached (`actions/cache`, key `godot-<version>-linux-editor`).

## Evidence every result must carry

Repository and branch, exact commit SHA, configuration (workflow inputs, `sim_args`, `set`), seed, save precision regime
(`save_precision`: full, mixed or default; ND-16), expected and actual result, run id and artifact name, and pass, fail or
unresolved. The existing artifacts hold them: `ci-validation-<run>` (validation.json: sha, suites, failures), `ci-report-*-shard*`
(per-suite logs), `sim-gate` (gate.json, SIM_GATE_SUMMARY.md: findings against the accepted baseline, determinism lines),
`fr-seedN-results` (summary.json with commit, seed, days, stop reason, save precision; findings; workbook). Records cite the run id.

A gate difference is never accepted by replacing the baseline: the accepted baseline (`df67e8e`) changes only with the owner's
approval (BASELINE-AUTH-01), and every difference is explained before a test is called successful.

## What stays local

- Quick feedback while writing a change: one focused test or a few game days (seconds to minutes).
- Interactive play, visual checks (screenshots looked at), and device checks (phone, controller, Windows PC, two devices: MP-05).
- Probes that read local scratch data. Everything that decides a merge runs in Actions.
