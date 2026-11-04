# CI architecture for Build 25 Revision 1 (owner directive 2026-11-04: shorter validation wall-clock)

Goal: shorten the GitHub Actions wall-clock for validating B25R1 without weakening coverage, determinism or conservation.
Simulation rules and gameplay are unchanged. Status: **Tests: done and dispatched once for validation. Campaign twin
concurrency: done. Sim-gate split: helpers built and checked offline, but no workflow wiring yet (see section 3).
Segment resume: not done.**

## 1. Inventory (measured)

| workflow / job | what it does | measured | independent? |
|---|---|---|---|
| tests.yml `test` (4 shards, every 4th suite) | 172 Godot suites + Python checks + 10-day sim | shards 13-64 min; slowest shard 50-64 min (runs 41580777660, 41733575763, 41735516442, 41737006430, 41740708833) | suites are independent processes |
| long-sims.yml `sim-gate` / release.yml `sim-gate` | `sim_suite.py --jobs 4`: 26 runs (19 sims, 6 probes, perf) | 60 min (41737024930) and 98 min (41733570702); timeout 120 | runs are independent processes; the evaluation needs all of them |
| flight-recorder-seed.yml `seg1..seg4` | one 365-day world in 100-day segments | up to 345 min each | **sequential**: each segment continues the previous segment's saved world |
| flight-recorder-campaign.yml `seed` | one chain per seed (and per twin) | | seeds and twins are independent |
| campaign `scenarios` | 8 targeted scenarios | | independent; already parallel beside the campaign |
| campaign `lives` | reports A-I and the twin comparison | | needs both chains finished |

Setup cost per Tests runner: about 40 s (checkout, cached Godot, pip, import 13-20 s).

Per-suite seconds come from each shard's `results.jsonl` (in the `ci-report-*` artifacts). The medians are in
`tools/ci_timings.json`; suites that timed out are left out (`farm_shared_save_test` hit the 1800 s limit twice on
branch runs). Total suite time is about 119 min plus 6.5 min for the Python checks and the 10-day run.

## 2. Tests: eight time-balanced shards (done)

- `tools/ci_plan.py tests-shard` packs the one suite list longest-first onto the least-loaded shard, using
  `tools/ci_timings.json`. Shard 0 starts with the Python + 10-day run time. A suite with no timing (for example one just
  added to the list) goes to the least-loaded shard. The list in tests.yml is unchanged: the integration worker can keep
  adding suites as before.
- Each suite line is kept whole. The old `awk '{print $1}'` dropped arguments: `judgment_perf.gd -- --sizes 100 --days 10`
  ran without its arguments. It runs with them again, as it did before the shards.
- Each shard writes `shard.json` (commit, list hash, the full list, its assignment). A new `report` job
  (`tools/ci_consolidate.py`) fails if: a shard is missing, cancelled, skipped or timed out; a shard ran another commit or
  another list; or the shards do not cover the list exactly once. It also prints the results by the owner's logical groups.
- Every job checks out `github.sha`. `fail-fast: false`. Timeout 150 → 90 min a shard.
- Only shard 0 reports the python and sim steps. Other shards used to report them as "skipped", which made a passing
  shard look INCOMPLETE.

**Logical groups or time-balanced shards?** Time-balanced. The logical groups are very uneven: economy and conservation
is about 53 suites, including the 12-min courier suite, while presence is 4. The slowest group would set the wall-clock.
Balanced packing gives eight shards at about 15.7 min each (the 12.4-min `courier_live_test` is the floor). The groups
still appear in the report.

Estimated wall-clock, from the measured medians: **before** 50-64 min (slowest of 4 shards). **After** about 17 min
(16 min of suites + about 1 min setup), with a worst case of about 30 min if the runner is 1.8x slower. Runner minutes:
about the same suite time, plus 4 more setups (about 3 extra runner-minutes a run).

## 3. Simulation gate split (helpers done; workflows NOT changed)

- `tools/ci_plan.py gate-plan --parts 4` reads exactly the jobs `sim_suite.py` would run on this commit, rotating seeds
  included. It does this by running `main()` up to the job start, so there is no second list. It packs them into 4 parts
  and keeps each determinism pair (eq_s1/det_s1, x20_on_s1/x20_on_det_s1) together. Estimated 23-26 min a part,
  against 60-98 min for the whole gate on one runner.
- Each part runs `sim_suite.py --only <part>`, then `gate-record`. `gate-merge` checks that every run is present exactly
  once, on the same commit, with tool exit 0 or 1. It writes the merged `gate.json`, and `sim_suite.py --reuse` then
  evaluates it as one whole gate (baselines, determinism pairs, coverage, workbook).
- Checked offline: the outputs of run 41737024930 were split into 4 parts, merged and evaluated. The result was
  **identical** to evaluating the unsplit directory (same 47 findings, history, notes and coverage). A missing part makes
  `gate-merge` fail.
- **Not wired yet:** a reusable `sim-gate.yml` (plan → 4 parts → gather that writes the same `sim-gate` /
  `sim-gate-archives` artifacts) called by release.yml and by the long-sims gate mode. It was left out because the gate
  must not be dispatched for validation tonight, and release.yml should not change without a validating run.
  sim_suite.py is not modified.

## 4. 365-day campaign

- Still sequential, by design: segments 1-4 of one seed form one continuous world. Each segment goes on from the
  previous segment's saved world, so they are never independent runs.
- **Twin concurrency (done):** with `--twin`, the plan lists seeds first and twins after, and `max-parallel: 2` made each
  twin wait for its seed. With `--twin`, max-parallel is now 8, so every seed and its twin start together from the same
  initial state, each on its own runner. Without `--twin`, FLIGHT-REC-01's default ("Maximum concurrency: Two
  simulation jobs", directive 2026-11-02) is unchanged. **For the lead and owner (DCR-01):** this is an intentional
  revision of that limit for the twin campaign only. Two seeds with twins means 4 concurrent simulation jobs, plus the
  8 targeted scenarios, which were already parallel.
- Seeds run in parallel. The targeted scenarios already run beside the campaign (`needs: plan` only).
- **Resume (not done):** `recover_run` only prints an earlier run's checkpoints. A failed segment cannot yet continue
  from the last saved world in a new run. The design: download `fr-seed<N>-state<K>` from the earlier run (same commit
  checked against its status.json), skip segments 1..K, and fetch their archives for the analysis. This needs
  `actions: read` on the campaign callers.

## 5. Consolidated report

`tools/ci_consolidate.py` makes one report for one commit from the Tests shards, the gate's `sim-gate` artifact and the
campaign's `fr-seed*-results` / `fr-living-world-seed*` artifacts, plus each run's `gh run view --json
headSha,status,conclusion,jobs`. It contains: each source and group, pass or fail, days reached, conservation,
determinism, missing evidence, wall-clock and runner minutes. It fails on a missing, cancelled, skipped, timed-out or
failed job, or on evidence from another commit. It runs inside tests.yml (`report` job). For the gate and campaign,
run it by hand after `gh run download`:

```sh
gh run download <gate run> -n sim-gate -D dl/gate; gh run view <gate run> --json headSha,status,conclusion,jobs > gate.json
gh run download <campaign run> -p 'fr-*-results' -p 'fr-living-world-*' -D dl/camp; gh run view <campaign run> --json headSha,status,conclusion,jobs > camp.json
python3 tools/ci_consolidate.py --sha <sha> --gate dl/gate --meta gate=gate.json --campaign dl/camp --meta campaign=camp.json --require gate,campaign
```

## 6. Cost and limits

The repository is public, so standard GitHub-hosted runners cost nothing. The free plan allows 20 concurrent jobs
(GitHub documentation). I could not check this account's actual limit from this session. Peak concurrency: 8 Tests
shards; the campaign with twins uses 4 chains + 8 scenarios = 12.

## Concurrency and one source commit (owner amendment 2026-11-04, GitHub parallel validation)

| Workflow / mode | Concurrency group | Cancels |
|---|---|---|
| Tests, full | `tests-<ref>` | only an older full Tests run on the same branch (kept: a superseded run is useless) |
| Tests, `only` input (e.g. the flight-recorder regression) | `tests-only-<run id>` | nothing; nothing cancels it |
| long-sims `gate` (full simulation check) | `long-sims-own-<run id>` | nothing |
| long-sims `flight` (365-day campaign, seed and `--twin`) | `long-sims-own-<run id>`, inner `flight-recorder-<run id>` | nothing |
| release | `release-<ref>` | nothing (`cancel-in-progress: false`) |

All release-gating runs are dispatched on `wip/b25r1` at one head and nothing is pushed there until they finish; each run
checks out `github.sha` and every report names it, so the matrix row's SHA is the run's own. Artifacts carry the run id in
their names, so parallel runs never overwrite each other.
