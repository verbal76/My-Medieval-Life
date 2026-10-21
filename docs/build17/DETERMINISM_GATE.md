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
