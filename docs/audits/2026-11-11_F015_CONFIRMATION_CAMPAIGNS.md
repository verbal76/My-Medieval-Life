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

Runs 42912791595 (fbfd6ad) and 42912797405 (3d515d6): pending at the time of writing; added below when they finish.

## Status

The controlled experiment supports the investigation's conclusion (`docs/audits/2026-11-10_F015_SEED2_POPULATION.md`): the seed 2
gap is consistent with chaotic divergence, not a systematic effect of F015/P99. The verdict waits for seeds 3 and 4; F015/P99 is
not merged until then.
