# Build 18 365-day runs after the chapel alms (CHAPEL-R2): report

Run 39904513181, `wip/build18` at `61ec528`, `economy_sim.gd --days 365 --every 10`, seeds 1-4, one run per seed. Before = run 39874405723 at `9a86f5c` (my `LONG_RUNS_365.md`). Read-only analysis; nothing run or committed. Parsed logs: `/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad/lr365/alms/seed{1..4}.log`.

## Release gate: integrity is clean

**No leak, no FATAL line, no script error in any seed.** All four jobs succeeded (exit 0), reached day 365 (37 `day N:` lines each, days 10 to 360 and 365), currency leak 0, item leaks `{}`, coin-source and holder mismatches 0 (summary and `currency:` lines), and no `FATAL` line was printed by any seed (the step greps the full `sim.log` for it). Seed 1 took 204 minutes against 113 before (seeds 2-4: 86 / 114 / 101 minutes); the cause is not in the logs and it finished normally. One run per seed, so no determinism comparison is made here.

## What the logs do and do not carry

The Simulate step now prints the day lines, `neighbours:` and `migration` lines and the end totals. It does not print the `growth:` lines, and the stats `chapel_alms_coins` and `chapel_alms_households` are not in any printed line or in `summary.json`. So:
- **Total alms given and households helped: not logged.** I could not derive them; the chapel fund's inflow (offerings) is not logged either. Available: the chapel fund at day 365 (`currency.holders.chapel`) and the chapel's food store.
- **Chapel fund over time: not logged** (end value only).
- Adults and employed: end totals only. Manor hands: `manor_hand` does not appear in `people.by_job` at day 365 in any seed, before or after (so zero manor hands at the end in both).
- Each pre/post pair is two divergent trajectories of a chaotic simulation: the pairs are identical up to about day 30-50 (for example seed 2 identical on days 10, 30, 50) and then differ in everything, including population and migrants. Differences that go in both directions across seeds are within that noise; only consistent ones are read as effects.

## 1. Integrity per seed


| Seed | Job | Runtime | Exit | Script errors | Currency leak | Item leaks | FATAL lines | Day lines | Fingerprint |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 120253284916 | 12219 s (204 min) | 0 | 0 | 0 | {} | none | 37 | `f794dadc13eba4be68f7b1777e013c31` |
| 2 | 120253284885 | 5137 s (86 min) | 0 | 0 | 0 | {} | none | 37 | `21912f7f37e9febc6747ddef9d58d032` |
| 3 | 120253284914 | 6857 s (114 min) | 0 | 0 | 0 | {} | none | 37 | `a63d94f7acaff1a167cdf1c5c6ed453a` |
| 4 | 120253284955 | 6056 s (101 min) | 0 | 0 | 0 | {} | none | 37 | `5ee0667f6dea6f4cf628c6fae47193e0` |


Fingerprints differ from the pre-alms runs, as expected for changed code (`9a86f5c` -> `61ec528`).

## 2. Before and after

### B. Before and after, days 100 and 365 (pre = run 39874405723 at 9a86f5c; post = run 39904513181 at 61ec528)

| Seed | Day | Run | Alive | Food days | Starved | Unemployed | Treasury | Median hh purse | World coins | Settlement people / coins | Village paid net |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 100 | pre | 149 | 16.3 | 0 | 26 | 549 | 105 | 7397 | 370 / 4959 | -4290 |
| 1 | 100 | post | 147 | 18.1 | 0 | 22 | 548 | 105 | 7297 | 363 / 5080 | -4169 |
| 1 | 365 | pre | 397 | 13.0 | 0 | 188 | 4 | 9 | 8691 | 433 / 4307 | -4942 |
| 1 | 365 | post | 374 | 15.5 | 0 | 144 | 4 | 5 | 8892 | 479 / 4131 | -5118 |
| 2 | 100 | pre | 137 | 22.8 | 0 | 13 | 358 | 90 | 5946 | 304 / 6679 | -2886 |
| 2 | 100 | post | 143 | 21.5 | 0 | 15 | 321 | 86 | 5801 | 304 / 6824 | -2741 |
| 2 | 365 | pre | 310 | 26.3 | 0 | 122 | 2 | 4 | 7469 | 409 / 6384 | -3181 |
| 2 | 365 | post | 353 | 21.5 | 0 | 153 | 29 | 19 | 6403 | 317 / 6740 | -2825 |
| 3 | 100 | pre | 170 | 14.8 | 0 | 26 | 42 | 101 | 7049 | 308 / 5593 | -3808 |
| 3 | 100 | post | 151 | 16.2 | 0 | 26 | 176 | 93 | 7261 | 320 / 5525 | -3876 |
| 3 | 365 | pre | 329 | 16.9 | 0 | 135 | 2 | 5 | 8949 | 518 / 4799 | -4602 |
| 3 | 365 | post | 311 | 16.1 | 0 | 121 | 15 | 8 | 8938 | 484 / 4938 | -4463 |
| 4 | 100 | pre | 123 | 20.7 | 0 | 14 | 396 | 79 | 6352 | 396 / 6111 | -3167 |
| 4 | 100 | post | 125 | 22.4 | 0 | 16 | 547 | 106 | 6727 | 397 / 5917 | -3361 |
| 4 | 365 | pre | 338 | 19.0 | 0 | 124 | 0 | 4 | 8919 | 573 / 4555 | -4723 |
| 4 | 365 | post | 360 | 20.8 | 0 | 155 | 0 | 10 | 8123 | 585 / 6034 | -3244 |


Day-100 reads (same run, SIM-01): post-alms alive 147 / 143 / 151 / 125, food days 18.1 / 21.5 / 16.2 / 22.4, unemployed 22 / 15 / 26 / 16, treasury 548 / 321 / 176 / 547, median purse 105 / 86 / 93 / 106; no starvation. Day 100 is little changed from before: the alms rule has had two months to act and the two runs are close (for example seed 1 treasury 549 vs 548, median purse 105 vs 105).

### C. End-of-run money, food and work (day 365)

| Seed | Run | Chapel fund | Villagers (purses) | Treasury | World | Chapel share | Missed meals no money / no food | Relief grain | Chapel food store (pts) | Adults / employed / unemployed | Births counter | Migrants in | Manor tax in / wages out |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | pre | 7375 | 817 | 4 | 8691 | 84.9% | 82 / 3 | 477 | 230400 | 235 / 47 / 188 | 487 | 201 | 10336 / 9566 |
| 1 | post | 7561 | 976 | 4 | 8892 | 85.0% | 57 / 1 | 445 | 253440 | 189 / 45 / 144 | 457 | 173 | 11671 / 10694 |
| 2 | pre | 5099 | 906 | 2 | 7469 | 68.3% | 348 / 6 | 267 | 375300 | 168 / 46 / 122 | 453 | 127 | 11354 / 8976 |
| 2 | post | 4431 | 1281 | 29 | 6403 | 69.2% | 3 / 2 | 285 | 356360 | 198 / 45 / 153 | 433 | 155 | 10721 / 8770 |
| 3 | pre | 7119 | 806 | 2 | 8949 | 79.6% | 50 / 32 | 309 | 241540 | 183 / 48 / 135 | 520 | 151 | 7146 / 6784 |
| 3 | post | 6986 | 1019 | 15 | 8938 | 78.2% | 9 / 46 | 408 | 214160 | 168 / 47 / 121 | 480 | 144 | 7990 / 7446 |
| 4 | pre | 7466 | 823 | 0 | 8919 | 83.7% | 16 / 7 | 366 | 286140 | 167 / 43 / 124 | 445 | 155 | 10449 / 9754 |
| 4 | post | 6374 | 798 | 0 | 8123 | 78.5% | 79 / 5 | 356 | 340440 | 201 / 46 / 155 | 549 | 165 | 9843 / 9230 |


### D. Unemployed, treasury and median purse over time (pre / post)

| Seed | Series | d10 | d50 | d100 | d150 | d200 | d250 | d300 | d330 | d365 |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | unemployed | 1 / 1 | 12 / 12 | 26 / 22 | 36 / 38 | 60 / 55 | 67 / 78 | 96 / 116 | 146 / 141 | 188 / 144 |
| 1 | treasury | 182 / 182 | 285 / 287 | 549 / 548 | 115 / 94 | 1 / 81 | 5 / 4 | 14 / 0 | 5 / 4 | 4 / 4 |
| 1 | median purse | 108 / 108 | 107 / 107 | 105 / 105 | 63 / 97 | 30 / 75 | 13 / 23 | 15 / 15 | 9 / 7 | 9 / 5 |
| 1 | alive | 109 / 109 | 125 / 123 | 149 / 147 | 168 / 173 | 214 / 187 | 234 / 247 | 280 / 311 | 342 / 345 | 397 / 374 |
| 1 | migrants in | 0 / 0 | 4 / 4 | 21 / 20 | 33 / 37 | 56 / 48 | 64 / 94 | 111 / 155 | 168 / 171 | 201 / 173 |
| 1 | first day >=100 with treasury <=10 | pre: 180, post: 220 | | | | | | | | |
| 2 | unemployed | 0 / 0 | 6 / 6 | 13 / 15 | 21 / 27 | 38 / 43 | 62 / 66 | 80 / 95 | 97 / 123 | 122 / 153 |
| 2 | treasury | 134 / 134 | 144 / 144 | 358 / 321 | 130 / 35 | 53 / 39 | 94 / 94 | 28 / 7 | 2 / 94 | 2 / 29 |
| 2 | median purse | 120 / 120 | 94 / 94 | 90 / 86 | 60 / 75 | 26 / 24 | 19 / 14 | 7 / 17 | 4 / 14 | 4 / 19 |
| 2 | alive | 111 / 111 | 125 / 125 | 137 / 143 | 141 / 146 | 184 / 180 | 229 / 229 | 251 / 280 | 267 / 316 | 310 / 353 |
| 2 | migrants in | 0 / 0 | 3 / 3 | 10 / 11 | 22 / 20 | 66 / 55 | 84 / 88 | 104 / 124 | 109 / 144 | 127 / 155 |
| 2 | first day >=100 with treasury <=10 | pre: 310, post: 160 | | | | | | | | |
| 3 | unemployed | 0 / 0 | 7 / 7 | 26 / 26 | 47 / 39 | 73 / 62 | 89 / 62 | 105 / 79 | 109 / 95 | 135 / 121 |
| 3 | treasury | 30 / 30 | 177 / 177 | 42 / 176 | 1 / 5 | 38 / 102 | 47 / 24 | 1 / 16 | 2 / 2 | 2 / 15 |
| 3 | median purse | 118 / 118 | 96 / 96 | 101 / 93 | 36 / 61 | 21 / 32 | 15 / 16 | 14 / 11 | 8 / 8 | 5 / 8 |
| 3 | alive | 111 / 111 | 119 / 119 | 170 / 151 | 196 / 173 | 230 / 186 | 279 / 229 | 317 / 259 | 307 / 285 | 329 / 311 |
| 3 | migrants in | 0 / 0 | 1 / 1 | 34 / 20 | 58 / 44 | 96 / 53 | 129 / 93 | 136 / 107 | 136 / 124 | 151 / 144 |
| 3 | first day >=100 with treasury <=10 | pre: 110, post: 120 | | | | | | | | |
| 4 | unemployed | 0 / 0 | 10 / 10 | 14 / 16 | 23 / 32 | 24 / 49 | 39 / 55 | 81 / 69 | 102 / 108 | 124 / 155 |
| 4 | treasury | 152 / 152 | 283 / 401 | 396 / 547 | 120 / 192 | 19 / 28 | 35 / 2 | 5 / 3 | 19 / 0 | 0 / 0 |
| 4 | median purse | 127 / 127 | 149 / 130 | 79 / 106 | 87 / 84 | 70 / 80 | 23 / 17 | 20 / 14 | 9 / 14 | 4 / 10 |
| 4 | alive | 107 / 107 | 122 / 122 | 123 / 125 | 121 / 143 | 131 / 179 | 204 / 225 | 277 / 254 | 292 / 296 | 338 / 360 |
| 4 | migrants in | 0 / 0 | 2 / 2 | 5 / 6 | 8 / 23 | 30 / 53 | 78 / 71 | 122 / 86 | 123 / 124 | 155 / 165 |
| 4 | first day >=100 with treasury <=10 | pre: 210, post: 210 | | | | | | | | |


Facts, seed by seed, at day 365 (post vs pre):
- **Chapel fund:** 7,561 vs 7,375 (seed 1), 4,431 vs 5,099 (2), 6,986 vs 7,119 (3), 6,374 vs 7,466 (4). Share of the world's coins 85.0% / 69.2% / 78.2% / 78.5% (pre 84.9 / 68.3 / 79.6 / 83.7). The fund was not drained: it still holds 4.4k-7.6k coins at the end.
- **Alms given, households helped:** not logged (above).
- **Villagers' purses (total):** 976 / 1,281 / 1,019 / 798 vs 817 / 906 / 806 / 823. Median household purse 5 / 19 / 8 / 10 vs 9 / 4 / 5 / 4: higher in seeds 2-4 by 4 to 15 coins in the median, lower in seed 1 (9 to 5). Household purse minimum is 0-1 and maximum 170-287 (seed 2: 1 / 19 / 278).
- **Missed meals for no money:** 57 / 3 / 9 / 79 vs 82 / 348 / 50 / 16. Down in seeds 1-3 (seed 2 from 348 to 3), up in seed 4 (16 to 79). Missed meals for no food for sale: 1 / 2 / 46 / 5 vs 3 / 6 / 32 / 7. Relief grain 445 / 285 / 408 / 356 vs 477 / 267 / 309 / 366.
- **Food days (need basis):** 15.5 / 21.5 / 16.1 / 20.8 vs 13.0 / 26.3 / 16.9 / 19.0. Starvation 0 at every checkpoint of every seed, before and after.
- **Treasury and the day it empties** (first day from 100 with treasury <= 10): post 220 / 160 / 120 / 210 vs pre 180 / 310 / 110 / 210. Treasury at day 365: 4 / 29 / 15 / 0 (pre 4 / 2 / 2 / 0). The treasury still empties in all four seeds after day 100; in seed 2 earlier than before (day 160 vs 310; it recovers to 94 at day 330 and ends at 29). Manor tax in / wages out over the year: 11.7k / 10.7k, 10.7k / 8.8k, 8.0k / 7.4k, 9.8k / 9.2k.
- **Employed adults:** 45 / 45 / 47 / 46 vs 47 / 46 / 48 / 43. Manor hands: none at day 365 in any run.
- **Unemployed:** 144 / 153 / 121 / 155 vs 188 / 122 / 135 / 124 (down in seeds 1 and 3, up in 2 and 4).
- **Population:** 374 / 353 / 311 / 360 vs 397 / 310 / 329 / 338 (migrants in 173 / 155 / 144 / 165 vs 201 / 127 / 151 / 155).

## 3. Remaining unemployment: fixed capacity versus the chapel

Unemployed = adults - employed (definition in `LONG_RUNS_365.md` section 3). Decomposing the change between the two runs at day 365:

| Seed | Adults pre / post | Employed pre / post | Unemployed pre / post | Change in unemployed | From change in adults | From change in employed |
|---|---|---|---|---|---|---|
| 1 | 235 / 189 | 47 / 45 | 188 / 144 | -44 | -46 | +2 |
| 2 | 168 / 198 | 46 / 45 | 122 / 153 | +31 | +30 | +1 |
| 3 | 183 / 168 | 48 / 47 | 135 / 121 | -14 | -15 | +1 |
| 4 | 167 / 201 | 43 / 46 | 124 / 155 | +31 | +34 | -3 |

Facts:
- Employed adults are 43-48 in all eight runs. Between the two runs it changed by -2 / -1 / -1 / +3 places (seeds 1-4); the column 'From change in employed' below is that change's contribution to the unemployed count (sign reversed).
- The change in unemployed matches the change in adult count in every seed (within 3): the post-alms difference is the size of the adult population (births and migrants differ between the two trajectories), not jobs.
- The job places are the same set in every run: 12 farmers (6 fields x 2), 5-6 merchants, 2 smiths, 2 carpenters, and a few others, and zero manor hands at day 365.
- Share of adults without a job at day 365: post 76% / 77% / 72% / 77% (pre 80% / 73% / 74% / 74%).

Reading (interpretation, labelled): all remaining unemployment (121-155 adults, 72-77% of adults) is explained by fixed job capacity against a larger adult population; none of it can be attributed to the chapel from these data, and the alms did not create or remove places (employed 45-47 against 43-48 before). The earlier question of whether the empty treasury closes manor-hand places stays untested by these logs: there are no manor hands in either set of runs at day 365.

## 4. Settlements: one-line check

Nothing regressed in the totals: settlement coins at day 365 are 4,131 / 6,740 / 4,938 / 6,034 (pre 4,307 / 6,384 / 4,799 / 4,555) and people 479 / 317 / 484 / 585 (pre 433 / 409 / 518 / 573), with no FATAL (settlement books balanced at every checkpoint); the village remains a net receiver (-5,118 / -2,825 / -4,463 / -3,244). Two points in the detail: seed 2 Higham fell from 1,567 coins and 128 people (day 100) to 472 coins and 52 people (day 365), with 32 deaths there (pre-alms Higham in seed 2 ended 1,061 / 127); Netherton reached 0 people in seed 1 and 1 in seed 2, as it did before (2 / 2 / 0 / 2). Hunger migrants into the village are still 132-154 of the 144-173 moves.

### E. Settlements (coins / people)

| Seed | Day | Run | Wulstead | Netherton | Garton | Higham | Bourton |
|---|---|---|---|---|---|---|---|
| 1 | 100 | pre | 1117 / 128 | 212 / 9 | 1775 / 66 | 1335 / 136 | 520 / 31 |
| 1 | 100 | post | 1127 / 119 | 212 / 6 | 1755 / 67 | 1450 / 144 | 536 / 27 |
| 1 | 365 | pre | 394 / 59 | 224 / 2 | 2119 / 171 | 1417 / 190 | 153 / 11 |
| 1 | 365 | post | 1110 / 152 | 212 / 0 | 1173 / 125 | 1485 / 198 | 151 / 4 |
| 2 | 100 | pre | 1169 / 74 | 188 / 11 | 3164 / 59 | 1586 / 127 | 572 / 33 |
| 2 | 100 | post | 1231 / 73 | 188 / 11 | 3186 / 59 | 1567 / 128 | 652 / 33 |
| 2 | 365 | pre | 677 / 58 | 131 / 2 | 4061 / 191 | 1061 / 127 | 454 / 31 |
| 2 | 365 | post | 693 / 64 | 85 / 1 | 5058 / 187 | 472 / 52 | 432 / 13 |
| 3 | 100 | pre | 1148 / 85 | 306 / 20 | 2163 / 66 | 1409 / 94 | 567 / 43 |
| 3 | 100 | post | 1140 / 85 | 300 / 19 | 2131 / 74 | 1424 / 100 | 530 / 42 |
| 3 | 365 | pre | 1112 / 129 | 129 / 0 | 1713 / 200 | 1649 / 176 | 196 / 13 |
| 3 | 365 | post | 1082 / 101 | 91 / 8 | 1941 / 210 | 1687 / 154 | 137 / 11 |
| 4 | 100 | pre | 2274 / 116 | 140 / 6 | 1469 / 68 | 1482 / 155 | 746 / 51 |
| 4 | 100 | post | 2175 / 116 | 112 / 11 | 1623 / 67 | 1369 / 158 | 638 / 45 |
| 4 | 365 | pre | 1925 / 242 | 155 / 2 | 888 / 87 | 1223 / 180 | 364 / 62 |
| 4 | 365 | post | 1242 / 210 | 36 / 5 | 2904 / 173 | 1157 / 139 | 695 / 58 |
## 5. Verdict

**Release gate (integrity): clean.** No leak, FATAL line or script error; all four seeds reached day 365; fingerprints recorded; one run per seed.

Remaining concerns, classified:
| Concern | Class | Evidence |
|---|---|---|
| Alms totals and the chapel fund over time are not logged; the alms stats cannot be read | Evidence gap (not a defect) | stats absent from printed lines and `summary.json` |
| The chapel fund is not drained: 4,431-7,561 coins (69-85% of world coins) at day 365 after alms | **Possible defect: needs root-cause check** | The rule gives everything beyond owed wages plus 7 days of wages to households short of their necessity reserve, yet the fund ends at 4.4k-7.6k and the median household purse is 5-19. Whether no household is short on the service day, whether the reserve is lower than these purses, or whether offerings refill the fund each week is not visible in these logs |
| Missed meals for no money fell in seeds 1-3 (82 to 57, 348 to 3, 50 to 9) but rose in seed 4 (16 to 79) | Outcome (mixed) | end totals only; trajectories diverge |
| Unemployment 121-155 adults (72-77%) | Structural | employed 45-47 in every run; change tracks the adult count; zero manor hands |
| Treasury empties in all seeds (days 120-220) | Outcome | seed 2 empties earlier than before (160 vs 310) |
| Housing crowding and population growth through hunger migrants | Structural | 132-154 hunger moves in; unchanged by alms |
| Firewood counter | Defect in the harness counter (previously reported) | `no_firewood_nights` 3,199 / 3,275 / 3,245 / 3,397 still sums all household entries including ended ones; effect on the game is not shown |
| Shops end with no coins (14 of 17 trader roles at zero in seed 2) | Outcome | `money:` traders block |
| Seed 2 Higham decline, Netherton and Bourton dwindling | Outcome | section 4 |
| Seed 1 runtime 204 minutes vs 113 | Observation | no ledger effect; cause not in logs |

Facts only; no tuning is recommended.

## Lead's check: do the alms reach households in a long run? (seed 2, 150 days, local, code 61ec528)

The long-run logs do not print the alms counters, so a throwaway probe ran seed 2 for 150 days on the release code and
printed, at each service day, the fund, the alms given, the households helped and the households still short afterwards:

| Day | Fund | Offerings (total) | Wages (total) | Alms (total) | Household payments | Households short after the service |
|---|---|---|---|---|---|---|
| 27 | 945 | 1,085 | 140 | 0 | 0 | 0 |
| 62 | 2,222 | 2,540 | 315 | 3 | 1 | 0 |
| 97 | 2,898 | 3,411 | 490 | 23 | 10 | 0 |
| 146 | 3,522 | 4,325 | 735 | 68 | 35 | 0 |

Alms are paid, and after every service day no household is left short of its necessity reserve. Households are rarely short
by that measure (it is their foreseeable need less the food and coins they hold), so the alms are small and the fund keeps
growing: offerings run far above wages plus the households' measured need. That is the approved rule ("fill up to their
reserve") with the provisional offering values, not a defect; changing either is the owner's decision.
