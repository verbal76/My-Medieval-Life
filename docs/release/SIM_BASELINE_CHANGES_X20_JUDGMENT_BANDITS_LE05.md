# Simulation baseline replaced: judgment calibration, bandit intelligence and tool repair (2026-10-31)

Owner decisions 2026-10-31 (`docs/directives/2026-10-31_x20_merged_validation_decisions.md`: "establish the updated 30-day
baseline once"; `docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md`; `docs/directives/2026-10-31_sjdh_c4_bandit_intelligence.md`).

## What changed in the default game (economy off)

- Bandit intelligence and incident counting (X20-BANDIT-AI, X20-JUDG-C3; merge `8dc6cef`).
- Judgment calibration: decisions, hearsay fading, mixed feelings (X20-JUDG-C1, C2, C5; merge `17432f0`).
- Tool repair in normal play (LE05-REPAIR; merge `25663e5`; rental stays behind the switch).
- Recorder trace fix `a3643c8`: changes nothing in the world.

## Evidence (local `tools/sim_gate.py`, seeds 1 and 2, days 10 and 30, code `a3643c8`)

| Run | Seed 1 day 30 | Seed 2 day 30 |
|---|---|---|
| Old baseline (`ed6360f` line) | `d4a1d71d…`, alive 117, currency 3733, treasury 6 | `40a3f050…`, alive 111, currency 3766, treasury 1 |
| a3643c8 against the old baseline | `c4f2fb94ae8509cfb647f78194cc2a2d`, alive 117, currency 4416, treasury 165 | `a2363b9fea6daaa0ee90bc9f0ebe1d39`, alive 122, currency 4081, treasury 22 |
| `--write` from a3643c8 | identical | identical |
| Re-check | PASS, identical | PASS, identical |

- **Determinism:** three runs of the same code gave identical results.
- **Conservation:** currency leak 0 and no item leaks at every checkpoint of all three runs.
- **The differences are behaviour:**
  - judgment now chooses among comparable sellers, buyers and workers;
  - bandits weigh danger and stop re-robbing;
  - smiths mend tools.
  
  Village currency is higher because the treasury and households hold more coins, with every holder reconciled (leak 0).
