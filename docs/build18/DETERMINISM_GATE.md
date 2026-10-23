# Build 18 determinism gate (REL18-DET)

## 2026-10-23, all Build 18 work merged (code `9a86f5c` on `wip/build18`)

`tools/sim_gate.py` (seeds 1 and 2, checkpoints at days 10 and 30, each seed in its own process and data directory; one
30-day run per seed, SIM-01). Baseline written (`--write`) on the integrated code, then a second, independent run:
`determinism gate: PASS, identical to the baseline`. The Build 17 baseline is kept unchanged as
`docs/release/sim_baseline_build17.json`; `docs/release/sim_baseline.json` is now the Build 18 baseline.

| Seed | Day | Fingerprint | Alive | Households | Currency | Leaks |
|---|---|---|---|---|---|---|
| 1 | 10 | `cc3edc39e29c7b7b95e293a4f28cb463` | 109 | 25 | 3325 | currency 0, items {} |
| 1 | 30 | `e13c98a11c39e4e8e7aa36969878dc7b` | 116 | 25 | 4784 | currency 0, items {} |
| 2 | 10 | `7cda7e1110efdd7b72b6cdaec7a577dd` | 111 | 25 | 3315 | currency 0, items {} |
| 2 | 30 | `20c9e29ed14431e002fc212bbb05e5b0` | 118 | 25 | 4397 | currency 0, items {} |

The fix after it (the capability profile no longer records on load, `World.load_dict`) and the test updates change only
the load path and tests, which the simulation does not run, so the gate result stands for the final code.
