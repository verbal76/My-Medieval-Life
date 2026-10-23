# Build 18 365-day runs: report (REL18-LONGRUN, WDR-004-C, SET-C, REG-EVAL-01)

Run 39874405723 (`long-sims.yml`), `wip/build18` at `9a86f5c`, `economy_sim.gd --days 365 --every 10`, seeds 1-4, one run per
seed. All four jobs exited 0. Analyst: read-only; no code changed, nothing run, nothing committed.

## Sources, and what is still missing

Two sources, both job logs:
1. The four original job logs (120156402386 / 120156402285 / 120156402359 / 120156402408): `summary.json`, FARMLINE, HERDLINE, the
   last 30 `sim.log` lines. Section 1 comes from these.
2. Recovery run 39893372350, job 120218052815 (`recover`), which downloaded run 39874405723's four artifacts and printed per seed
   `summary.json`, every `day N:` line (every 10 days, 37 per seed: days 10..360 and 365), the `neighbours:`, `migration` and `growth:`
   lines, and the end totals (`people:`, `food:`, `money:`, `trade:`, `currency:`, `ledger flows:`). Parsed copy:
   `/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad/lr365/recovered.log`. Sections 2-6 come from it. Its
   end totals match the original summaries (for example seed 1 chapel 7,375, villagers 817, treasury 4, fingerprint line unchanged).

Still genuinely missing (not in either source):
- **The chapel fund over time.** Only the day-365 holder split exists (`currency.holders.chapel`). The day lines carry the world coin total,
  the treasury and the households' cash, not the chapel.
- **Settlement-side detail beyond the neighbours line:** per-settlement businesses opening or closing (SET-D), households and ages
  inside settlements, and prices. The neighbours line gives people, coins, treasury, trader coins, hungry and died per settlement.
- **Village prices, wheat, production and trade over time.** The day lines have no price, wheat or production fields; those exist only as
  end totals (and `farm.wheat_price` 2 at day 365). The day-100 column of the scarcity audit therefore covers what the day lines carry.
- **Adult count per checkpoint.** The day lines give "unemployed" only, not adults or employed.
- **Day 0.** The first sample is day 10; the day-0 state is taken from the baseline log and the sim's start totals.
- The `LEAKS:` line itself. Replaced by `currency.leak`, exit code and `samples` count (section 1).

## 1. REL18-LONGRUN: integrity per seed

| Seed | Job | Runtime | Exit | Script errors | Currency leak | Item leaks | FATAL | Reached day 365 | Final fingerprint |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 120156402386 | 6,776 s (113 min) | 0 | 0 | 0 | none (`{}`) | none | yes | `7bb401e9e8c026b083dd3026cfa7c0f2` |
| 2 | 120156402285 | 7,983 s (133 min) | 0 | 0 | 0 | none | none | yes | `64de918138f545ed6d32651f2f4bed9e` |
| 3 | 120156402359 | 6,481 s (108 min) | 0 | 0 | 0 | none | none | yes | `614c50eacf3b4c5fdb15b26129568bc2` |
| 4 | 120156402408 | 4,458 s (74 min) | 0 | 0 | 0 | none | none | yes | `79c907e32e158e2108bcb9c4ae14ef16` |

Evidence for each cell:
- Leak and items: `summary.json` `currency.leak` = 0, `currency.coin_sources_mismatch` = 0, `currency.holders_mismatch` = 0,
  `item_leaks` = `{}` in all four. The sim exits non-zero on a currency or item leak, and every exit code is 0.
- FATAL: none in the last 30 log lines of any seed. A FATAL stops the run at its checkpoint; every run has `samples` = 38 in
  FARMLINE (start sample + days 10..360 + day 365), so the run went to day 365. A settlements-books FATAL (`regions.audit`,
  coins/goods/people mismatch) would also have stopped it early, and none did. I could not read the printed `LEAKS:` line
  itself; the values above stand in for it.
- Confirmed by the recovery job (120218052815): it grepped the whole `sim.log` of each seed for `FATAL` among other patterns, and returned no FATAL line for any seed; every seed shows exactly 37 `day N:` lines (days 10 to 360 and 365).
- Script errors: `script_errors` = 0 (the workflow counts `SCRIPT ERROR` lines in `sim.log`).
- Godot exit noise in every log: "N ObjectDB instances were leaked at exit" (1,598 / 1,568 / 1,664 / 1,512) and "38 resources
  still in use at exit". Engine shutdown messages after the result was written; not counted as script errors. Whether Build 17
  logs carried the same I did not check.
- Runtimes: Build 17 runs (MIN-G) took 66-118 min; these took 74-133 min (seed 2 longest in both).
- Determinism: one run per seed (SIM-01). No second run exists to compare fingerprints with, so none is claimed.


## 2. Checkpoints (from the recovered day lines)

Start (day 0, same in every seed): 104 alive, 25 households, about 3,000 coins (3,009 / 2,966 / 2,942 / 3,057), 748 wheat, treasury 270 (baseline log).
"Food days" here is the day line's need-based figure (`days_of_need`); the FARMLINE `farm.food_days` quoted in the first version of this report (20.9 / 37.2 / 27.3 / 27.1 at day 365) is a different measure and is not comparable with these.
"Unemployed" is the counter defined in section 3. "World coins" is the village currency total (villagers, chapel, treasury, bandits, loot, tills, player). "Village paid net" is the cumulative net of coins the village paid to the five settlements, negative when the settlements paid the village.

### Required read: day 100 (SIM-01, from the same run) and day 365

| Seed | Day | Alive | Food days | Starved | Unemployed | Treasury | Median household cash | World coins | Households (counter) | Settlement people / coins | Village paid net |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 100 | 149 | 16.3 | 0 | 26 | 549 | 105 | 7,397 | 26 | 370 / 4,959 | -4,290 |
| 1 | 365 | 397 | 13.0 | 0 | 188 | 4 | 9 | 8,691 | 28 | 433 / 4,307 | -4,942 |
| 2 | 100 | 137 | 22.8 | 0 | 13 | 358 | 90 | 5,946 | 25 | 304 / 6,679 | -2,886 |
| 2 | 365 | 310 | 26.3 | 0 | 122 | 2 | 4 | 7,469 | 29 | 409 / 6,384 | -3,181 |
| 3 | 100 | 170 | 14.8 | 0 | 26 | 42 | 101 | 7,049 | 25 | 308 / 5,593 | -3,808 |
| 3 | 365 | 329 | 16.9 | 0 | 135 | 2 | 5 | 8,949 | 26 | 518 / 4,799 | -4,602 |
| 4 | 100 | 123 | 20.7 | 0 | 14 | 396 | 79 | 6,352 | 25 | 396 / 6,111 | -3,167 |
| 4 | 365 | 338 | 19.0 | 0 | 124 | 0 | 4 | 8,919 | 31 | 573 / 4,555 | -4,723 |

Starvation deaths are 0 at every checkpoint of every seed (`starved 0` on all 148 day lines). "Other deaths" (all old age) at day 100 / 365: 15 / 91, 16 / 86, 16 / 96, 15 / 73. Baseline (earlier commit 36beb67, seed 1, day 90): 129 alive, 14 unemployed, treasury 498, food 17.0, settlement coins 4,610.

### All checkpoints (days 10, 30, 50, 100, 150, 200, 250, 300, 365)

Columns: day, alive, other (old-age) deaths, food days, unemployed, treasury, household cash min/median/max, world coins, traders unable to buy, households counter, settlement people, settlement coins, village paid net.

**Seed 1**

| Day | Alive | Other deaths | Food days (need basis) | Unemployed | Treasury | Household cash min/med/max | World coins | Traders unable to buy | Hh (counter) | Settlement people | Settlement coins | Village paid net |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | 109 | 2 | 4.4 | 1 | 182 | 32/108/205 | 3325 | 3 | 25 | 290 | 8954 | -295 |
| 30 | 116 | 4 | 7.4 | 3 | 36 | 11/115/592 | 4784 | 4 | 25 | 334 | 7495 | -1754 |
| 50 | 125 | 9 | 11.0 | 12 | 285 | 2/107/274 | 5413 | 5 | 25 | 366 | 6887 | -2362 |
| 100 | 149 | 15 | 16.3 | 26 | 549 | 1/105/268 | 7397 | 8 | 26 | 370 | 4959 | -4290 |
| 150 | 168 | 19 | 20.7 | 36 | 115 | 1/63/198 | 7776 | 13 | 27 | 372 | 4684 | -4565 |
| 200 | 214 | 22 | 19.6 | 60 | 1 | 1/30/341 | 7909 | 14 | 27 | 403 | 4629 | -4620 |
| 250 | 234 | 39 | 20.6 | 67 | 5 | 0/13/377 | 8067 | 14 | 27 | 477 | 4471 | -4778 |
| 300 | 280 | 63 | 19.5 | 96 | 14 | 0/15/381 | 8401 | 14 | 28 | 484 | 4317 | -4932 |
| 365 | 397 | 91 | 13.0 | 188 | 4 | 0/9/436 | 8691 | 15 | 28 | 433 | 4307 | -4942 |

**Seed 2**

| Day | Alive | Other deaths | Food days (need basis) | Unemployed | Treasury | Household cash min/med/max | World coins | Traders unable to buy | Hh (counter) | Settlement people | Settlement coins | Village paid net |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | 111 | 4 | 4.4 | 0 | 134 | 25/120/241 | 3315 | 3 | 25 | 254 | 9253 | -312 |
| 30 | 118 | 8 | 8.7 | 4 | 160 | 26/110/345 | 4397 | 7 | 25 | 291 | 8171 | -1394 |
| 50 | 125 | 9 | 12.8 | 6 | 144 | 10/94/539 | 5296 | 7 | 25 | 310 | 7309 | -2256 |
| 100 | 137 | 16 | 22.8 | 13 | 358 | 0/90/334 | 5946 | 10 | 25 | 304 | 6679 | -2886 |
| 150 | 141 | 18 | 30.9 | 21 | 130 | 0/60/279 | 6254 | 13 | 27 | 321 | 6371 | -3194 |
| 200 | 184 | 24 | 29.5 | 38 | 53 | 0/26/251 | 6310 | 14 | 27 | 327 | 6484 | -3081 |
| 250 | 229 | 38 | 28.2 | 62 | 94 | 1/19/395 | 6937 | 14 | 28 | 337 | 6271 | -3294 |
| 300 | 251 | 66 | 29.8 | 80 | 28 | 0/7/233 | 6991 | 16 | 29 | 349 | 6415 | -3150 |
| 365 | 310 | 86 | 26.3 | 122 | 2 | 0/4/227 | 7469 | 15 | 29 | 409 | 6384 | -3181 |

**Seed 3**

| Day | Alive | Other deaths | Food days (need basis) | Unemployed | Treasury | Household cash min/med/max | World coins | Traders unable to buy | Hh (counter) | Settlement people | Settlement coins | Village paid net |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | 111 | 1 | 3.8 | 0 | 30 | 18/118/350 | 3602 | 2 | 25 | 261 | 8770 | -631 |
| 30 | 114 | 6 | 7.6 | 2 | 90 | 47/108/452 | 4943 | 7 | 25 | 303 | 7485 | -1916 |
| 50 | 119 | 12 | 11.5 | 7 | 177 | 13/96/274 | 5806 | 9 | 25 | 330 | 6737 | -2664 |
| 100 | 170 | 16 | 14.8 | 26 | 42 | 1/101/297 | 7049 | 13 | 25 | 308 | 5593 | -3808 |
| 150 | 196 | 19 | 17.5 | 47 | 1 | 0/36/317 | 7732 | 14 | 26 | 307 | 5043 | -4358 |
| 200 | 230 | 26 | 17.8 | 73 | 38 | 1/21/323 | 8113 | 13 | 26 | 327 | 4851 | -4550 |
| 250 | 279 | 38 | 16.8 | 89 | 47 | 1/15/319 | 8285 | 13 | 26 | 381 | 4911 | -4490 |
| 300 | 317 | 62 | 16.6 | 105 | 1 | 1/14/254 | 8516 | 14 | 26 | 404 | 4979 | -4422 |
| 365 | 329 | 96 | 16.9 | 135 | 2 | 0/5/199 | 8949 | 14 | 26 | 518 | 4799 | -4602 |

**Seed 4**

| Day | Alive | Other deaths | Food days (need basis) | Unemployed | Treasury | Household cash min/med/max | World coins | Traders unable to buy | Hh (counter) | Settlement people | Settlement coins | Village paid net |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | 107 | 4 | 4.9 | 0 | 152 | 30/127/255 | 3483 | 3 | 25 | 293 | 8877 | -401 |
| 30 | 123 | 6 | 7.5 | 4 | 161 | 1/150/279 | 4695 | 5 | 25 | 345 | 7728 | -1550 |
| 50 | 122 | 11 | 11.8 | 10 | 283 | 0/149/311 | 5731 | 8 | 25 | 360 | 6692 | -2586 |
| 100 | 123 | 15 | 20.7 | 14 | 396 | 0/79/293 | 6352 | 13 | 25 | 396 | 6111 | -3167 |
| 150 | 121 | 18 | 29.0 | 23 | 120 | 0/87/256 | 7260 | 10 | 26 | 450 | 5322 | -3956 |
| 200 | 131 | 28 | 32.6 | 24 | 19 | 1/70/163 | 7593 | 12 | 29 | 488 | 5352 | -3926 |
| 250 | 204 | 38 | 27.6 | 39 | 35 | 0/23/230 | 7737 | 14 | 30 | 512 | 5208 | -4070 |
| 300 | 277 | 56 | 23.4 | 81 | 5 | 0/20/229 | 8181 | 15 | 31 | 520 | 5062 | -4216 |
| 365 | 338 | 73 | 19.0 | 124 | 0 | 0/4/231 | 8919 | 16 | 31 | 573 | 4555 | -4723 |

Other facts for the whole run (end totals, original summary and recovered `money:` / `trade:` lines):

| Seed | Manor ledger, whole run: tax in / wages out | Caravan coins in (settlements to village) / out | Other outside coins in | Births counter | Migrants into village | Old-age deaths | Missed meals (no money / no food for sale) | Relief grain |
|---|---|---|---|---|---|---|---|---|
| 1 | 10,336 / 9,566 | 8,739 / 3,797 | 740 | 487 | 201 | 91 | 82 / 3 | 477 |
| 2 | 11,354 / 8,976 | 8,557 / 5,376 | 1,322 | 453 | 127 | 86 | 348 / 6 | 267 |
| 3 | 7,146 / 6,784 | 7,622 / 3,020 | 1,405 | 520 | 151 | 96 | 50 / 32 | 309 |
| 4 | 10,449 / 9,754 | 8,347 / 3,624 | 1,139 | 445 | 155 | 73 | 16 / 7 | 366 |

"Other outside coins in" = `currency.external_in` minus `trade.coins_in` (newcomers' purses and the like). The "births counter" is `npcs.size() - start.npcs`, so it includes every migrant who arrived, newcomers and returning outlaws; it is not a count of babies. Subtracting migrants in gives an upper bound for babies born: 286 / 326 / 369 / 290.

## 3. Unemployment: what the counter counts, and when it rose

Definition (`game/tests/economy_sim.gd`, `_sample`, lines ~553-566): over living villagers with `role == "adult"`, `adults += 1`; `if n.job != "": with_job += 1`; `unemployed = adults - with_job`. So it counts **adults whose `job` string is empty**.
- Children and elders are not in it (elders have their job cleared on retirement, `life.gd` ~205). Anyone with any job, including farmer or manor hand, counts as employed. Income does not matter: a household living on savings or a partner's pay contributes its jobless adults.
- A child who comes of age becomes an adult with the job left empty (`life.gd` ~227). A migrant who arrives is also an adult without a job until `seek_work` places them.
- Placement is by openings computed each morning (`npc_brain.gd` `job_market`): manor hand = `(treasury - reserve) / (wage x 20)` (wage 6, reserve 10 days of obligations), so 0 whenever the treasury is below roughly 120 coins plus the reserve; farmer = 2 per field x 6 fields = 12 (12 farmers in every seed); woodcutter, hunter and miner by trees, game and ore left; tailor, barber, preacher, church assistant one place each; merchants, smiths, carpenters, tanners, cooks and tavernkeepers by succession only.

Per checkpoint (recovered day lines; adult counts are not on the day lines):

| Seed | d10 | d30 | d50 | d70 | d100 | d150 | d200 | d250 | d300 | d330 | d365 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 unemployed | 1 | 3 | 12 | 13 | 26 | 36 | 60 | 67 | 96 | 146 | 188 |
| 1 treasury | 182 | 36 | 285 | 516 | 549 | 115 | 1 | 5 | 14 | 5 | 4 |
| 1 migrants in (cum.) | 0 | 1 | 4 | 5 | 21 | 33 | 56 | 64 | 111 | 168 | 201 |
| 1 alive | 109 | 116 | 125 | 129 | 149 | 168 | 214 | 234 | 280 | 342 | 397 |
| 2 unemployed | 0 | 4 | 6 | 6 | 13 | 21 | 38 | 62 | 80 | 97 | 122 |
| 2 treasury | 134 | 160 | 144 | 362 | 358 | 130 | 53 | 94 | 28 | 2 | 2 |
| 2 migrants in (cum.) | 0 | 2 | 3 | 4 | 10 | 22 | 66 | 84 | 104 | 109 | 127 |
| 2 alive | 111 | 118 | 125 | 129 | 137 | 141 | 184 | 229 | 251 | 267 | 310 |
| 3 unemployed | 0 | 2 | 7 | 16 | 26 | 47 | 73 | 89 | 105 | 109 | 135 |
| 3 treasury | 30 | 90 | 177 | 115 | 42 | 1 | 38 | 47 | 1 | 2 | 2 |
| 3 migrants in (cum.) | 0 | 0 | 1 | 8 | 34 | 58 | 96 | 129 | 136 | 136 | 151 |
| 3 alive | 111 | 114 | 119 | 136 | 170 | 196 | 230 | 279 | 317 | 307 | 329 |
| 4 unemployed | 0 | 4 | 10 | 4 | 14 | 23 | 24 | 39 | 81 | 102 | 124 |
| 4 treasury | 152 | 161 | 283 | 425 | 396 | 120 | 19 | 35 | 5 | 19 | 0 |
| 4 migrants in (cum.) | 0 | 1 | 2 | 3 | 5 | 8 | 30 | 78 | 122 | 123 | 155 |
| 4 alive | 107 | 123 | 122 | 121 | 123 | 121 | 131 | 204 | 277 | 292 | 338 |

Facts from the table:
- Seed 1: 1 at day 10, 12 at day 50, 26 at day 100, 60 at day 200, 96 at day 300, 188 at day 365. Steepest after day 300 (+92 in 65 days).
- Seed 2: 0, 6, 13, 38, 80, 122. Seed 3: 0, 7, 26, 73, 105, 135. Seed 4: 0, 10, 14, 24, 81, 124 (flat at 23-24 between days 150 and 210, then rising).
- Day 100: 26 / 13 / 26 / 14 (the baseline had 14 at day 90, the Build 17 end of year 6-30). Day 365: 188 / 122 / 135 / 124, 5.2 to 9.4 times the day-100 value.
- The rise is continuous from about day 50, with a faster phase in the second half of the year (day 250 on).
- Treasury: falls from 549 / 358 / 396 (day 100, seeds 1, 2, 4) to 5 or less at day 180 / 310 / 210 and stays near 0-50 after; seed 3 was already 42 at day 100 and 0-52 from day 110. In seed 2 the unemployed count rose from 13 (day 100) to 62 (day 250) while the treasury was still 94-358, so the empty treasury is not the whole story there.
- Migrants into the village (cumulative, from the migration line, mostly reason "in:hunger"): 201 / 127 / 151 / 155 by day 365; the unemployed at day 365 are 188 / 122 / 135 / 124, i.e. 94% / 96% / 89% / 80% of that. Seed 4's migrants in were 5 at day 100 and 30 at day 200, then 155; its unemployed rose in step (14, 24, 124).

Classification:
- **Outcome, not a counting artefact.** The counter measures adults without a job. The rise follows two mechanisms visible in the logs: a fixed set of job places (12 farmers, 6 merchants, 2 smiths and 2 carpenters in every seed, no new fields, trades or stalls: `building.sites_finished` 2-3, `stall_relocations` 0) and growth of the adult population largely through migrants in from the settlements.
- Interpretation (labelled): the empty manor treasury removes the manor-hand places from about day 110-310 depending on the seed, which sharpens the effect in the last third of the year. The data do not show how many of the arriving migrants are adults, or what share of the unemployed are migrants.
- **Possible defect: needs root-cause check (low confidence):** the earlier note that employed adults fell from about 74-80 (Build 17, derived) to 43-48 stands, and the cause is not established. The treasury's decline from about 400-630 to near 0 is in the logs; what drains it is not separated in the day lines. The whole-run manor ledger shows tax in 7.1k-11.4k and wages out 6.8k-9.8k.

## 4. WDR-004-C scarcity audit: day 100 against day 365

Values per seed in order 1 / 2 / 3 / 4. "Not logged at day 100" marks fields that exist only as end totals (the day lines carry no price, wheat or production figures).

| Area | Day 100 | Day 365 | How the world responds (facts first) |
|---|---|---|---|
| Food (need-based days) | 16.3 / 22.8 / 14.8 / 20.7 | 13.0 / 26.3 / 16.9 / 19.0 | Within 13-26 days at both points, always above the 10-day household runway; no starvation at any of the 148 checkpoints. Mean hunger 68 / 68 / 68 / 70 -> 71 / 71 / 70 / 71 |
| Wheat | not logged at day 100 | stock 748 -> 15.9k / 24.7k / 16.6k / 18.9k; price 2; made 79.6k-83.0k, used 57.9k-67.0k | Production exceeds use by about 20-30% over the year; a stock builds. Exports of wheat to the caravan: 44 / 1,229 / 38 / 725 |
| Missed meals | not logged at day 100 | no money: 82 / 348 / 50 / 16; no food for sale: 3 / 6 / 32 / 7 | Small against 95k-120k pottage made; seed 2 highest. Relief grain 477 / 267 / 309 / 366 |
| People | 149 / 137 / 170 / 123 | 397 / 310 / 329 / 338 | Growth; 68-74% of the increase after day 100 is migrants in (180 of 248, 117 of 173, 117 of 159, 150 of 215; section 5) |
| Ore | iron ore and coal 0 left in the mine in all four seeds (day 10: 201-244 iron ore, 146-192 coal); copper 0; stone 285 / 280 / 288 / 269 | stone 201 / 240 / 246 / 232; iron, coal, copper 0; seams worked out 26 / 22 / 20 / 22 | Mines of metal ore are gone by day 100 in every seed (baseline: gone by day 45). Response: the village imports from the settlements' traders iron ore 378 / 626 / 243 / 240, coal 163 / 286 / 77 / 204 over the year and exports iron bars 480 / 504 / 376 / 408; miners stay 3-5. Raw metal supply is replaced by trade, not by new deposits in these logs |
| Logs, planks, trees | logs 1,371 / 3,916 / 2,234 / 1,596; planks 131 / 124 / 132 / 126; trees 165 / 174 / 173 / 175 | logs 183 / 2,579 / 931 / 217; planks 106 / 191 / 153 / 160; trees 181 / 182 / 182 / 192 | Log stock falls most in seeds 1 and 4 (also the seeds with the most "no firewood" households, section 4 note); planks flat; trees recovering |
| Firewood | not logged at day 100 | households without logs per night, summed: 3,057 / 3,417 / 3,325 / 4,465 | The harness counter loops over every household entry, including ended ones, so it overstates; by how much is not logged. No effect of cold appears in the day lines |
| Wildlife | wild 99 / 90 / 64 / 91, penned 30 / 19 / 26 / 27 | wild 96 / 100 / 91 / 97, penned 31 / 18 / 19 / 30 | Wild stock holds; seed 3's wild count recovers from 64 |
| Livestock | not logged at day 100 | cows 5 in every seed; chickens 12 / 0 / 0 / 12 (seed 2 laid 8 eggs in the year, seed 3 552) | Chickens died out in seeds 2 and 3 (same as Build 17); cow keeper short of feed or coins 39 / 17 / 12 / 2 days |
| Traders unable to buy | 8 / 10 / 13 / 13 | 15 / 15 / 14 / 16 | Rises. At day 365 (seed 1 `money:`) cooks, carpenters, smiths, tanners, the goods and food merchants and the tavernkeeper all hold 0 coins (`zero` = n) and are below their floor; merchant funds 25 / 0 / 18 / 1. The shops cannot restock from villagers who hold coins; this is bankruptcy-like and an outcome under WDR-022 |
| Household cash (min / median / max) | 1 / 105 / 268; 0 / 90 / 334; 1 / 101 / 297; 0 / 79 / 293 | 0 / 9 / 436; 0 / 4 / 227; 0 / 5 / 199; 0 / 4 / 231 | Median household purse falls to 4-9 coins (91-96% lower than at day 100) while a few households still hold 200-440 |
| Treasury | 549 / 358 / 42 / 396 | 4 / 2 / 2 / 0 | Empty from day 180 / 310 / 110 / 210 (section 3) |
| Employment | 26 / 13 / 26 / 14 unemployed | 188 / 122 / 135 / 124 | Section 3 |
| Housing | beds 111 / 111 / 113 / 111 for 149 / 137 / 170 / 123 people; crowded households 2 / 2 / 1 / 0 | beds 126 / 126 / 118 / 126 for 397 / 310 / 329 / 338 people; crowded 24 / 20 / 21 / 23; houses built 3 / 3 / 1 / 3; empty houses for sale 0 | Beds grow 5-15; people grow 1.9-2.7 times. 33 / 31 / 27 / 29 fertile couples live in "full" households (no longer a bar to births, EQ-08) |
| Trade with the five | net -4,290 / -2,886 / -3,808 / -3,167 | net -4,942 / -3,181 / -4,602 / -4,723 | The caravan runs every 2 days (182 visits); see section 5 |
| Wealth | world coins 7,397 / 5,946 / 7,049 / 6,352 | 8,691 / 7,469 / 8,949 / 8,919 | Money supply rises through outside inflow; its location is the chapel (below) |

Chapel and treasury trajectory (numbers only; the chapel's spending is being audited separately):
- Chapel fund over time: **not logged.** Only the end: 7,375 / 5,099 / 7,119 / 7,466 coins (84.9% / 68.3% / 79.6% / 83.7% of the world's coins), plus a chapel food store of 230,400 / 375,300 / 241,540 / 286,140 food points at day 365 (`food.points_by_holder.chapel`; the households hold 49,663 / 66,254 / 46,691 / 52,179 and the villagers' packs 37,360 / 45,304 / 44,004 / 38,244; the village's daily need is 24,840 / 18,893 / 19,886 / 20,074 points).
- What is logged over time: the treasury (table above) and the median household purse. The world coin total rises from about 3,000 to 8,700 (seed 1: 3,325 at day 10, 7,397 at day 100, 8,691 at day 365). With household purses falling (median about 105-110 at day 10 -> 4-9 at day 365) while the world total rises, the growth is outside the households; the day lines do not say where.
- Treasury, seed by seed: 182 -> 633 (day 90) -> 549 (day 100) -> 1 (day 200) in seed 1; 134 -> 368 -> 358 -> 53 (day 200) -> 2 (day 330) in seed 2; 30 -> 177 (day 50) -> 42 -> 1 (day 150) in seed 3; 152 -> 425 (day 70) -> 396 -> 19 (day 200) -> 0 in seed 4.

Response to scarcity, in short (facts): the food system never fails in these runs (no starvation, a wheat surplus builds); mined metal runs out by day 100 and is replaced by imports from the settlements; money leaves the households (median purse falls 91-96% between day 100 and day 365) and the shops end with no coins; housing does not keep pace with people (beds +5 to +15 against +159 to +248 people); unemployment grows with the population. The logs show no response by the village that adds new places or beds beyond 1-3 houses.

## 5. SET-C and REG-EVAL-01: the regional economy

Source: the recovered `neighbours:` and `migration` lines at every 10 days. "Village paid net" is the cumulative net coins the village paid to the five (negative = the settlements paid the village). Baseline: `docs/investigations/2026-10-23_regional_economy.md`, 90 days, seed 1, commit `36beb67`: settlements' coins 9,249 -> 4,610, village paid net -4,639 at day 90 (4,927 received, 288 paid), people 261 -> 233.

### Settlements' totals over the year

| Seed | Day 0 / 10 coins | Day 50 | Day 100 | Day 150 | Day 200 | Day 300 | Day 365 | Change days 10-100 | Change days 100-365 | Village paid net at 100 / 365 |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 8,954 (d10) | 6,887 | 4,959 | 4,684 | 4,629 | 4,317 | 4,307 | -3,995 | -652 | -4,290 / -4,942 |
| 2 | 9,253 (d10) | 7,309 | 6,679 | 6,371 | 6,484 | 6,415 | 6,384 | -2,574 | -295 | -2,886 / -3,181 |
| 3 | 8,770 (d10) | 6,737 | 5,593 | 5,043 | 4,851 | 4,979 | 4,799 | -3,177 | -794 | -3,808 / -4,602 |
| 4 | 8,877 (d10) | 6,692 | 6,111 | 5,322 | 5,352 | 5,062 | 4,555 | -2,766 | -1,556 | -3,167 / -4,723 |

Settlement people (day 10 / 100 / 200 / 300 / 365): seed 1 290 / 370 / 403 / 484 / 433; seed 2 254 / 304 / 327 / 349 / 409; seed 3 261 / 308 / 327 / 404 / 518; seed 4 293 / 396 / 488 / 520 / 573. Start population is 261.

Per-settlement detail (people / coins / died so far):

**Seed 1** (cells: people / coins / died so far)

| Day | Wulstead | Netherton | Garton | Higham | Bourton | Total people / coins | Migration to settlements / to village (cumulative) |
|---|---|---|---|---|---|---|---|
| 10 | 76 / 2586 / 0 | 17 / 779 / 0 | 51 / 1214 / 0 | 110 / 3134 / 0 | 36 / 1241 / 0 | 290 / 8954 | 0 / 0 |
| 50 | 106 / 1726 / 0 | 15 / 274 / 0 | 60 / 2100 / 0 | 140 / 1979 / 0 | 45 / 808 / 0 | 366 / 6887 | 1 / 4 |
| 100 | 128 / 1117 / 4 | 9 / 212 / 7 | 66 / 1775 / 3 | 136 / 1335 / 5 | 31 / 520 / 21 | 370 / 4959 | 4 / 21 |
| 150 | 123 / 1138 / 18 | 6 / 224 / 10 | 75 / 1563 / 3 | 140 / 1393 / 14 | 28 / 366 / 23 | 372 / 4684 | 5 / 33 |
| 200 | 132 / 1131 / 19 | 4 / 224 / 12 | 93 / 1498 / 5 | 148 / 1425 / 21 | 26 / 351 / 27 | 403 / 4629 | 11 / 56 |
| 250 | 151 / 1119 / 21 | 3 / 224 / 12 | 118 / 1478 / 7 | 177 / 1425 / 22 | 28 / 225 / 27 | 477 / 4471 | 17 / 64 |
| 300 | 147 / 926 / 23 | 2 / 224 / 12 | 138 / 1588 / 7 | 179 / 1423 / 23 | 18 / 156 / 28 | 484 / 4317 | 26 / 111 |
| 365 | 59 / 394 / 49 | 2 / 224 / 12 | 171 / 2119 / 7 | 190 / 1417 / 25 | 11 / 153 / 28 | 433 / 4307 | 34 / 201 |

**Seed 2** (cells: people / coins / died so far)

| Day | Wulstead | Netherton | Garton | Higham | Bourton | Total people / coins | Migration to settlements / to village (cumulative) |
|---|---|---|---|---|---|---|---|
| 10 | 65 / 2491 / 0 | 23 / 824 / 0 | 34 / 1369 / 0 | 96 / 3260 / 0 | 36 / 1309 / 0 | 254 / 9253 | 0 / 0 |
| 50 | 74 / 1675 / 0 | 26 / 285 / 3 | 47 / 1766 / 0 | 119 / 2633 / 0 | 44 / 950 / 0 | 310 / 7309 | 2 / 3 |
| 100 | 74 / 1169 / 8 | 11 / 188 / 20 | 59 / 3164 / 0 | 127 / 1586 / 3 | 33 / 572 / 14 | 304 / 6679 | 6 / 10 |
| 150 | 88 / 1010 / 12 | 11 / 137 / 21 | 70 / 3681 / 0 | 125 / 1123 / 11 | 27 / 420 / 22 | 321 / 6371 | 20 / 22 |
| 200 | 83 / 924 / 19 | 3 / 131 / 21 | 94 / 3922 / 0 | 120 / 1073 / 19 | 27 / 434 / 28 | 327 / 6484 | 36 / 66 |
| 250 | 77 / 712 / 24 | 2 / 131 / 22 | 118 / 3932 / 0 | 112 / 1062 / 21 | 28 / 434 / 34 | 337 / 6271 | 40 / 84 |
| 300 | 65 / 762 / 25 | 2 / 131 / 22 | 149 / 4007 / 0 | 104 / 1061 / 23 | 29 / 454 / 37 | 349 / 6415 | 46 / 104 |
| 365 | 58 / 677 / 25 | 2 / 131 / 22 | 191 / 4061 / 0 | 127 / 1061 / 24 | 31 / 454 / 41 | 409 / 6384 | 51 / 127 |

**Seed 3** (cells: people / coins / died so far)

| Day | Wulstead | Netherton | Garton | Higham | Bourton | Total people / coins | Migration to settlements / to village (cumulative) |
|---|---|---|---|---|---|---|---|
| 10 | 68 / 2341 / 0 | 24 / 841 / 0 | 45 / 1177 / 0 | 88 / 3153 / 0 | 36 / 1258 / 0 | 261 / 8770 | 0 / 0 |
| 50 | 87 / 1739 / 0 | 27 / 376 / 0 | 59 / 1624 / 0 | 113 / 2121 / 0 | 44 / 877 / 0 | 330 / 6737 | 1 / 1 |
| 100 | 85 / 1148 / 10 | 20 / 306 / 8 | 66 / 2163 / 1 | 94 / 1409 / 10 | 43 / 567 / 8 | 308 / 5593 | 5 / 34 |
| 150 | 72 / 1124 / 18 | 13 / 171 / 12 | 79 / 1883 / 1 | 109 / 1464 / 10 | 34 / 401 / 24 | 307 / 5043 | 12 / 58 |
| 200 | 82 / 1124 / 22 | 3 / 129 / 18 | 104 / 1833 / 1 | 112 / 1502 / 13 | 26 / 263 / 26 | 327 / 4851 | 29 / 96 |
| 250 | 83 / 1118 / 24 | 3 / 129 / 18 | 145 / 1833 / 1 | 135 / 1574 / 13 | 15 / 257 / 27 | 381 / 4911 | 45 / 129 |
| 300 | 101 / 1117 / 24 | 3 / 129 / 18 | 158 / 1833 / 5 | 135 / 1649 / 19 | 7 / 251 / 27 | 404 / 4979 | 50 / 136 |
| 365 | 129 / 1112 / 25 | 0 / 129 / 19 | 200 / 1713 / 6 | 176 / 1649 / 22 | 13 / 196 / 27 | 518 / 4799 | 65 / 151 |

**Seed 4** (cells: people / coins / died so far)

| Day | Wulstead | Netherton | Garton | Higham | Bourton | Total people / coins | Migration to settlements / to village (cumulative) |
|---|---|---|---|---|---|---|---|
| 10 | 81 / 2536 / 0 | 19 / 788 / 0 | 44 / 1372 / 0 | 106 / 3003 / 0 | 43 / 1178 / 0 | 293 / 8877 | 0 / 0 |
| 50 | 94 / 2287 / 0 | 23 / 250 / 2 | 61 / 1481 / 0 | 135 / 1928 / 0 | 47 / 746 / 9 | 360 / 6692 | 3 / 2 |
| 100 | 116 / 2274 / 0 | 6 / 140 / 20 | 68 / 1469 / 0 | 155 / 1482 / 5 | 51 / 746 / 15 | 396 / 6111 | 6 / 5 |
| 150 | 156 / 2060 / 0 | 3 / 140 / 22 | 71 / 1208 / 0 | 167 / 1168 / 15 | 53 / 746 / 23 | 450 / 5322 | 13 / 8 |
| 200 | 199 / 2126 / 0 | 3 / 154 / 23 | 71 / 1073 / 10 | 158 / 1254 / 30 | 57 / 745 / 29 | 488 / 5352 | 29 / 30 |
| 250 | 204 / 2002 / 1 | 3 / 155 / 23 | 74 / 1083 / 11 | 165 / 1233 / 33 | 66 / 735 / 31 | 512 / 5208 | 35 / 78 |
| 300 | 200 / 2023 / 5 | 2 / 155 / 23 | 78 / 935 / 12 | 170 / 1233 / 33 | 70 / 716 / 32 | 520 / 5062 | 37 / 122 |
| 365 | 242 / 1925 / 7 | 2 / 155 / 23 | 87 / 888 / 12 | 180 / 1223 / 34 | 62 / 364 / 45 | 573 / 4555 | 58 / 155 |

### Findings (facts)
- **The drain levelled off.** In every seed most of the loss is in the first 100 days (-2.6k to -4.0k from day 10), then the totals move by -295 to -1,556 over the next 265 days. Seeds 1 and 2 are nearly flat from day 150 (seed 1: 4,684 at day 150, 4,307 at day 365; seed 2: 6,371, 6,384). Seeds 3 and 4 keep a slow decline (seed 4: 5,322 at day 150, 4,555 at day 365).
- **It did not reverse.** The cumulative net payment never falls back by more than 92-164 coins from its deepest point in any seed (largest retrace: 120 / 164 / 138 / 92). At day 365 the settlements as a group still have paid the village net 4,942 / 3,181 / 4,602 / 4,723 coins. The change in the settlements' coins is accounted for almost exactly by the village's net payments (seed 1: 9,249 - 4,307 = 4,942 = village paid net).
- **Against the baseline.** At day 90 the settlements held 5,146 / 6,899 / 5,749 / 6,131 (seeds 1-4) against the baseline's 4,610 (seed 1 baseline 4,610 vs seed 1 here 5,146); village paid net at day 90: -4,103 / -2,666 / -3,652 / -3,147 against -4,639. The first-quarter drain is smaller than the baseline's in all four seeds and then stops growing. The baseline projected that the settlements would be "near their floors" in a year; here they hold 4,307 to 6,384 coins, 46-69% of the 9,249 start.
- **The village now buys from them, in small amounts.** Whole-run village purchases from the caravan: coins paid 3,797 / 5,376 / 3,020 / 3,624 (baseline 288 in 90 days); the caravan paid the village 8,739 / 8,557 / 7,622 / 8,347. Goods the village imported (`trade.imported`): iron ore 378 / 626 / 243 / 240, coal 163 / 286 / 77 / 204, copper swords 69 / 110 / 134 / 80, herbal poultice 120 / 12 / 53 / 68, spice 32, fine cloth 20, wheat seed 59 / 47 / 39 / 35; food bought from the settlements is small, in units over the whole year: pottage 12 / 62 / 20 / 24, roast meat 4 / 5 / 1 / 7, meat 3 / 20 / 0 / 0, eggs 9 / 0 / 0 / 0, wheat 0 / 0 / 0 / 1 (against 95k-120k pottage made in the village). Goods exported to them: iron bars 480 / 504 / 376 / 408, planks 585 / 750 / 895 / 1,091, herbal poultice 322 / 431 / 347 / 509, wheat 44 / 1,229 / 38 / 725, leather 108-134, flower seed 144-620.
- **People move to the village.** Migration into the village (reason "in:hunger" in 107-184 of the 127-201 moves): 21 / 10 / 34 / 5 by day 100 and 201 / 127 / 151 / 155 by day 365; out to the settlements 4 / 6 / 5 / 6 by day 100 and 34 / 51 / 65 / 58 by day 365 (reasons "out:land" and "out:marriage"). Migration into the village accelerates after day 200 (seed 1: 56 at day 200, 201 at day 365; seed 4: 30, then 155).
- **Settlements' own state at day 365.** Hungry: 10 / 2 / 7 / 19 people in the five at the end (peak 22 / 12 / 13 / 22). Died in the settlements (cumulative): 121 / 112 / 99 / 121, of which 40 / 45 / 37 / 40 by day 100. Settlement treasuries and traders end low: seed 1 Higham treasury 36 and trader 0; seed 4 Netherton trader 0 and Higham trader 0; the sum of the five settlement treasuries at day 365 is 95 / 640 / 203 / 138 (seed 2: Garton 551).
- **Two small settlements dwindle in every seed.** Netherton (16 at the start): 9 / 11 / 20 / 6 people at day 100, 2 / 2 / 0 / 2 at day 365 (seed 3: 0 people from about day 330, 129 coins left, 19 died). Bourton: 31 / 33 / 43 / 51 at day 100, 11 / 31 / 13 / 62 at day 365 (seeds 1 and 3 lose most). Wulstead in seed 1 fell from 141 (day 310) to 91 (day 330) and 59 (day 365), with 49 deaths in total by day 365; migration into the village in seed 1 rose by 57 between day 300 and day 330 and by 90 between day 300 and day 365.
- **Coin concentrates in some towns.** Garton in seed 2: 1,369 -> 3,164 (day 100) -> 4,061 coins (day 365), 64% of that seed's settlement coins at the end, with Netherton at 131, Bourton at 454, Higham 1,061 and Wulstead 677. Higham falls from 3,000-3,300 (day 10) to 1,061-1,649 and holds roughly steady after day 90. Wulstead's coins fall from 2,341-2,586 (seeds 1-3, day 10) to 394 / 677 / 1,112 (day 365); in seed 4 they stay at 1,925-2,536.
- Books: no FATAL at any checkpoint of any seed; the settlements' coin, goods and people mismatches were 0 throughout (a mismatch would have stopped the run). No settlement ledger fault.

### Conclusions for REG-EVAL-01 and REG-CIRC-D1
- **Did the drain continue, level off or reverse?** It levelled off. Fast loss to about day 100-150, then little movement; no reversal. Compared with the baseline (-4,639 net by day 90), the village's net intake from the settlements by day 90 is lower in all four seeds and then adds only -295 to -1,556 more in the remaining 265 days.
- **Is there evidence of a genuine circulation failure (REG-CIRC-D1)?** Partly, with limits. The evidence that a coin-circulation problem is still present: (1) in seed 2 Garton accumulates coins (1,369 to 4,061) while Netherton, Bourton, Higham and Wulstead each end below their day-10 level; this is the one-settlement-gains pattern the investigation attributed to Garton lacking cook, tanner and weaver; (2) Netherton falls to 0-4 people in all four seeds and Bourton to 11-13 in seeds 1 and 3, and 99-121 people died in the settlements in the year; (3) 107-184 people moved to the village for hunger, which means someone could not feed themselves where they lived. The evidence against a total failure: the settlements' total coins stop falling after about day 150 and none ran out; their combined population grew in every seed (261 to 409-573) with births from REG-DEMO-01; no settlement ledger broke. The logs cannot say whether the hunger migrants left because the settlement had no food or because they had no coins to buy it, nor whether Garton's gains are unspendable. That determination (the REG-CIRC-D1 question) needs per-settlement businesses, stock and price data, which these runs do not record.
- Interpretation only: the village remained a net importer of the settlements' coin through the year (about 3.2k-4.9k) and has absorbed 107-184 of their people; the village's own prosperity in the day lines (more people, a wheat surplus) accompanies a thinning of the smallest settlements.

### Data still missing for section 5
Settlement businesses opening or closing (SET-D), settlement households and ages, goods and prices per settlement, the split of the village's purchases by buyer (households, merchants, the treasury), and the settlements' food stocks. The migration line gives reasons only as counts.

## 6. Multi-generation (SET-D, B18-DP-05): facts only

The owner's rule: a 365-day run is not multi-generation verification. Facts from the logs only. The approved calendar is 8 days a year (regional investigation), so 365 days is about 45 game years.

Village (day 365; counters defined in section 2):

| Seed | Alive | Children / elders alive | Old-age deaths | Migrants in | Births counter minus migrants in (upper bound for babies) | Partnerships (growth line) | Households founded (growth) | Houses built | Beds / people | Crowded households |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 397 | 130 / 32 | 91 | 201 | 286 | 67 | 3 | 3 | 126 / 397 | 24 |
| 2 | 310 | 119 / 23 | 86 | 127 | 326 | 59 | 4 | 3 | 126 / 310 | 20 |
| 3 | 329 | 132 / 14 | 96 | 151 | 369 | 66 | 1 | 1 | 118 / 329 | 21 |
| 4 | 338 | 148 / 23 | 73 | 155 | 290 | 67 | 4 | 3 | 126 / 338 | 23 |

- Day 100 for comparison: 149 / 137 / 170 / 123 alive; partnerships 12 / 13 / 15 / 12; households founded 1 / 0 / 0 / 0; beds 111-113.
- The village's own descendants (alive minus migrants in) number about 196 / 183 / 178 / 183 at day 365, against 104 at the start. Interpretation: this is close to the Build 17 end-of-year populations (133-173), so most of the population increase over Build 17 is the migration added in Build 18.
- Settlements (REG-DEMO-01): people 261 at the start -> 433 / 409 / 518 / 573 at day 365. The neighbours line does not print births. Implied from the population identity (interpretation; assumes moves only between the village and the five): settlement births and other gains about 460 / 336 / 442 / 530 over the year, with 121 / 112 / 99 / 121 deaths and 201 / 127 / 151 / 155 people leaving for the village.
- Not logged: settlement births, ages, households and business formation (SET-D). Not verified here: that descendants take jobs or found households, that the settlements age by the village's life rules, or that inheritance works.

## 7. Summary

**Defects (broken ledger, FATAL, script error): none found.** All four runs reached day 365, exit 0, 0 script errors, currency leak 0, item leaks none, coin-source, holder and settlement-book mismatches 0 at every checkpoint, no FATAL.

**Possible defects: need root-cause check**
1. Firewood counter: `no_firewood_nights` (3,057 / 3,417 / 3,325 / 4,465) sums `world.gd`'s loop over every household entry, including ended households that can never hold a log, so it overstates the cold households by an unknown amount.
2. The chapel fund: 7,375 / 5,099 / 7,119 / 7,466 coins at day 365 (68-85% of the world's coins), with the median household purse falling from about 105 (day 100) to 4-9, an empty manor treasury, shops holding 0 coins, and 348 missed meals for no money in seed 2. Numbers only here (trajectory not logged); the spending is under separate audit.
3. Low confidence: employed adults fell to 43-48 from about 74-80 in Build 17 (derived). The rise in the counter is explained by fixed places and arrivals (section 3); what removed the Build 17 places is not shown.

**Notable outcomes (WDR-022: recorded, not defects)**
- Day 100 (per seed 1/2/3/4): alive 149 / 137 / 170 / 123; food 16.3 / 22.8 / 14.8 / 20.7 days; unemployed 26 / 13 / 26 / 14; treasury 549 / 358 / 42 / 396; settlement coins 4,959 / 6,679 / 5,593 / 6,111.
- Day 365: alive 397 / 310 / 329 / 338; food 13.0 / 26.3 / 16.9 / 19.0 days; unemployed 188 / 122 / 135 / 124; treasury 4 / 2 / 2 / 0; settlement coins 4,307 / 6,384 / 4,799 / 4,555. No starvation at any checkpoint.
- Unemployment rose steadily from about day 50 and fastest after day 250; it tracks the arrival of hunger migrants from the settlements (201 / 127 / 151 / 155 in by day 365; 68-74% of the post-day-100 population growth) and, in the second half, an empty treasury (empty from day 180 / 310 / 110 / 210).
- The settlements' coin drain levelled off after about day 100-150 and did not reverse; the village remained a net receiver (-4,942 / -3,181 / -4,602 / -4,723 paid net). The baseline's projection of settlements "near their floors" did not occur: they hold 46-69% of the starting coin.
- Circulation (REG-CIRC-D1): signs of an unresolved gap (Garton accumulating 1,369 -> 4,061 in seed 2; Netherton down to 0-4 people in all seeds; Bourton down to 11-13 in seeds 1 and 3; 107-184 hunger migrants), set against stable totals and growing combined populations. Not decidable without settlement business, stock and price data.
- The village's shops end with no coins (all trader roles at 0 in seed 1) while the households' median purse is 4-9; metal ore is gone from the village's mine by day 100 in every seed and is imported from the settlements instead.
- Housing: 111 -> 118-126 beds for 310-397 people; 20-24 crowded households.
- Chickens extinct in seeds 2 and 3 (as in Build 17); cows survive; wheat stock rises to 15.9k-24.7k.

**Genuinely missing:** the chapel fund over time; settlement businesses, households, goods and prices (SET-D); village prices, wheat and production at day 100; the adult count per checkpoint; day 0 from this run.

Source files: the four original job logs, recovery job 120218052815 (parsed in `/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad/lr365/`), `game/tests/economy_sim.gd`, `npc_brain.gd` (`seek_work`, `job_market`), `life.gd`, `chapel.gd`, `world.gd`, `game/data/balance.json`, `docs/build17/MIN_G_LONG_RUNS.md`, `docs/investigations/2026-10-23_regional_economy.md` and its 90-day baseline log.
