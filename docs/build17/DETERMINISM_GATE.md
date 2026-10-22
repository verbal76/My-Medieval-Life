# Build 17 determinism gate

`tools/sim_gate.py` (seeds 1 and 2, checkpoints at days 10 and 30, each seed in its own process and data directory).

## 2026-10-21, after MIN-D (owner direction: "Proceed with the Build 17 determinism gate using seeds 1 and 2 at days 10 and 30")

Code: `wip/build17` with MIN-A..D, CON-01 (first slice), DVW-B4, B14-07, DVW-A10, PL1-12, the crafts work, DVW-A12 (all rules)
and MIN-D with the owner's Q18-9 applied (no capability gates). The Build 16 baseline (recorded on `dbbb66a`) is kept
unchanged as `docs/release/sim_baseline_build16.json`; `docs/release/sim_baseline.json` is now the Build 17 baseline.

1. **Against the Build 16 baseline:** 27 differences, all Build 17's intended behaviour (deposits found and quarried,
   decay, contracts, the manor's new postings), with no coin or item leak at any checkpoint.
2. **Baseline written** (`--write`) on the merged code.
3. **Second run:** `determinism gate: PASS, identical to the baseline`.

| Seed | Day | Fingerprint | Alive | Households | Currency | Leaks |
|---|---|---|---|---|---|---|
| 1 | 10 | `4230942ed8f86322d3e717bee039e66e` | 106 | 24 | 4582 | currency 0, items {} |
| 1 | 30 | `329a078f78e90f4865e6d8b0dbba84ba` | 110 | 24 | 4922 | currency 0, items {} |
| 2 | 10 | `2d733f4ba1d5dcab25e5c41a6ebe18f0` | 108 | 24 | 4402 | currency 0, items {} |
| 2 | 30 | `3ad4b665361472818c01f68af26ee94b` | 116 | 24 | 4915 | currency 0, items {} |

Suites run on the final code (after the Q18-9 change): discovery 65, prospecting 54, quarry 39, underground 95,
contracts 75, world 339, run_tests 3536, start 499 steps, play 37 steps, parity 55, treasury 23, skills (pass); all 0
failures. Before that change all 42 suites passed on the DVW-A12 merge.

## Superseded note: pending re-baseline (done below)

CON-01's completion (merged at `9a56fcc`) changes behaviour (fewer contracts, signing in person), so the baseline above
describes the code of `b4d1223` and no longer matches the head. It is recorded once more after MIN-E is merged rather
than twice (owner: no repeated expensive runs); until then the leak check in CI (`tests.yml`, 10 days, seed 1) and
CON-01's own 30-day run (no leaks) are the conservation evidence for the newer code.

## CI on GitHub

- Actions run 39656594571 (`tests.yml`, workflow_dispatch on `wip/build17` at `9f229f7`, the MIN-A..D code): **success**,
  2026-10-21 18:52-19:00 UTC. The first CI run on the Build 17 branch (every suite in `tests.yml` plus the 10-day,
  seed-1 leak check).

## 2026-10-21, after CON-01 completion and MIN-E (code of `70900c0`)

Baseline re-recorded (`--write`) once for both changes, then a second run: `determinism gate: PASS, identical to the
baseline`. Suites on the same code: openpit 66, contracts 135, discovery 65, prospecting 54, quarry 39, underground 95,
crafts 20, world 339, run_tests 3537, start 499 steps, play 37 steps, parity 55, conservation 8, business 160, all 0
failures; check_resources, check_materials, check_assets 0 problems; Python unittest OK.

| Seed | Day | Fingerprint | Alive | Households | Currency | Leaks |
|---|---|---|---|---|---|---|
| 1 | 10 | `70990eea7661c4d477872ce9532c5760` | 101 | 24 | 4581 | currency 0, items {} |
| 1 | 30 | `e0f09912c01ec33944144171ca4d51ca` | 104 | 24 | 4909 | currency 0, items {} |
| 2 | 10 | `06629e3bf08d77378ce65a4bf604d6bc` | 111 | 24 | 4388 | currency 0, items {} |
| 2 | 30 | `55e36bea0034d69f6ca425cb9644d5fd` | 118 | 24 | 4918 | currency 0, items {} |

## 2026-10-21, after MIN-F and MIN-H (code of `49b6380`)

The cave's seams count as the village's own, so miners work the cave and the manor stakes an open pit: an intended
behaviour change. Baseline re-recorded, then a second run: `determinism gate: PASS, identical to the baseline`. Seed 1's
day-30 fingerprint also equals the MIN-F worker's independent 30-day run (`5063396929116f24aa7e707200ff846c`).

| Seed | Day | Fingerprint | Alive | Households | Currency | Leaks |
|---|---|---|---|---|---|---|
| 1 | 10 | `45983ca6722265e4948f673c4090d7f6` | 102 | 24 | 4580 | currency 0, items {} |
| 1 | 30 | `5063396929116f24aa7e707200ff846c` | 102 | 24 | 4897 | currency 0, items {} |
| 2 | 10 | `04ef9a89bcd248abfe7e629c37b7c2a7` | 109 | 24 | 4431 | currency 0, items {} |
| 2 | 30 | `a231b82551ba86a3f430a38105ebf930` | 114 | 24 | 4907 | currency 0, items {} |
