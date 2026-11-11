# F015/P99 confirmation campaigns (B25-F015-POP-01)

Owner directives 2026-11-10 (`docs/directives/2026-11-10_build25_merge_decisions.md` item 5; GitHub Actions testing directive
item 5). Question: is seed 2's 316 (fbfd6ad) vs 203 (3d515d6, F015/P99) population gap caused by the F015/P99 change, or by the
simulation's sensitivity to any small change? All runs: flight recorder campaigns, 365 days, every 10, recorded; default save
precision (these branches predate ND-16); measurements, not pass/fail (WDR-022).

## 1. Controlled experiment: seed 2 with one neutral change

`wip/b25-seed2-perturb` @ `cac6908` = fbfd6ad + a harness switch `--perturb N` (draws N values from the world's random stream right
after setup; no game code changed). Run 42913063605, `sim_args: --perturb 1`.

| Seed 2, day 365 | Alive | Births | Arrivals | Deaths (starvation) | Starved with means | Confirmed defects |
|---|---|---|---|---|---|---|
| fbfd6ad (run 42788018729) | 316 | 206 | 173 | 119 (28) | 18 | 0 |
| fbfd6ad + one extra random draw (run 42913063605) | 253 | 191 | 129 | 105 (9) | 7 | 0 |
| 3d515d6, F015/P99 (run 42832338970) | 203 | 137 | 93 | 92 (14) | 10 (+4 without) | 0 |

One extra random draw, with no code change, moved seed 2 by 63 villagers, 44 arrivals and 19 starvation deaths. Seed 2's outcome
is highly sensitive to any perturbation (the investigation found it turns on whether outside settlements collapse and send hunger
arrivals; earlier commits gave 189 to 322). The F015/P99 run's 203 lies below this pair but within the spread seen across commits.

## 2. Seeds 3 and 4 on both commits

Runs 42912791595 (fbfd6ad) and 42912797405 (3d515d6); every run reached day 365 with 0 confirmed defects.

| Seed | Alive fbfd6ad -> 3d515d6 | Births | Arrivals | Starvation deaths | Starved with means |
|---|---|---|---|---|---|
| 1 (42788018729 / 42832338970) | 339 -> 318 | 212 -> 222 | 201 -> 183 | 7 -> 3 | 5 -> 0 |
| 2 (same) | 316 -> 203 (perturbed fbfd6ad: 253) | 206 -> 137 (perturbed: 191) | 173 -> 93 (129) | 28 -> 14 (9) | 18 -> 10 (7) |
| 3 | 297 -> 314 | 227 -> 205 | 112 -> 140 | 6 -> 4 | 3 -> 4 |
| 4 | 304 -> 276 | 211 -> 154 | 145 -> 170 | 5 -> 11 | 1 -> 4 |
| Total | 1256 -> 1111 | 856 -> 718 | 631 -> 586 | 46 -> 32 | 27 -> 18 |

## Verdict (2026-11-11)

- Population: no consistent direction (seed 3 higher, seeds 1, 2, 4 lower); seed 2's gap is within the swing a neutral change
  produces (316 vs 253 on the same commit). Not established as a regression.
- Starvation: lower overall (46 -> 32), but seed 4 is higher (5 -> 11). Mixed.
- Births: lower in three of four seeds (856 -> 718, -16%); seed 4's drop (-57) exceeds the neutral-change swing seen on seed 2
  (-15). This is an unexplained difference: F015/P99 is NOT cleared for merge. Next: a targeted investigation of the birth rule's
  inputs on seeds 2 and 4 (which couples are held back and why, by day), on both commits, before any merge decision.
- P99's smith refusal streaks are reduced on seed 2 (no p:99 streak) but long refusal streaks of other villagers remain on all
  four seeds in both commits (for example seed 3 p:88, 2169 in a row on 3d515d6); these are separate findings for the register.
