# Build 17 MIN-G: 365-day runs (SIM-01)

Actions run 39692107077 (`long-sims.yml`), commit `7e19008` (game code identical to the release candidate `cd7439c`), seeds
1-4, 365 days, checkpoints every 10 days, one monitored run per seed. All four jobs exited 0. Read from the job logs
(summary JSON, FARMLINE, HERDLINE, the item ledger tail and the fingerprint); the per-checkpoint sample lines (days 30, 90,
100) are in the artifacts (`sim.json`), which cannot be downloaded through this session's proxy, so only end-of-run values
are reported here.

## Simulation integrity

| Seed | Runtime | Fingerprint | Coin leak | Item leaks | Script errors | FATAL |
|---|---|---|---|---|---|---|
| 1 | 66 min | `c250670e974664fdde10cb406fcf7671` | 0 | none | 0 | none |
| 2 | 118 min | `e93a6564ba35acfaa9d39a0385db02a4` | 0 | none | 0 | none |
| 3 | 70 min | `7f3a4387e3223dcee414f431fabfd634` | 0 | none | 0 | none |
| 4 | 93 min | `7fe94bda69e0b73f3d1ebf9b2d72bf3e` | 0 | none | 0 | none |

Determinism of this code: the gate on `cd7439c` (two independent runs identical, seeds 1-2, days 10/30;
`DETERMINISM_GATE.md`). The 365-day runs are one run per seed (SIM-01; no second run was needed).

## Economic outcomes at day 365 (WDR-022: recorded, not pass/fail)

| Seed | Alive | Households | Births | Deaths | Food days | Coins start -> end | Missed meals (no money) | Unemployed / adults |
|---|---|---|---|---|---|---|---|---|
| 1 | 159 | 33 | 129 | 70 old age | 113.8 | 2927 -> 9488 | 606 | 9 / 88 |
| 2 | 166 | 35 | 138 | 71 old age, 1 starvation | 136.6 | 2903 -> 9625 | 879 | 21 / 101 |
| 3 | 133 | 33 | 102 | 69 old age | 203.9 | 2869 -> 9226 | 2012 | 6 / 83 |
| 4 | 173 | 35 | 143 | 70 old age | 55.5 | 2954 -> 9737 | 5417 | 30 / 104 |

No famine sample in any run. Seams worked out: 26-28 a seed. Cow herds survived every seed; the chickens died out early
in seeds 2 and 3 (63 and 56 eggs against about 1,700 in seeds 1 and 4). Seed 4 is the poorest village (lowest food
reserve, most relief grain, most missed meals and unemployment): an economic outcome.

## Harness reporting defect found (no game effect)

`economy_sim.gd` counts every note containing " marks out " as a building site started. Build 17's open pits note
"... marks out an open pit ...", so a staked pit is counted as a site: seeds 2 and 3 each show one "site" with no finish,
open or given-up record. The game is unaffected; only the harness's `sites_started` count is wrong. Fix (one line, test
harness only): exclude open-pit notes. Not applied; recorded for the owner.
