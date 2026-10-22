# FARM-08: the shared-yield comparison, the cattle investigation and the wheat price floor

Owner directives of 2026-10-21 (`docs/directives/2026-10-21_farm08_cattle_investigation.md`,
`docs/directives/2026-10-21_build16_master_completion_directive.md` section 8). Register entries FARM-08, FARM-08B and
FARM-08C.

**Status: awaiting the owner's approval.** Both farming switches stay off in normal play: `shared_manor_farming`,
`seasonal_village_farming` and `shared_wheat_yield` are 0 in `game/data/balance.json`. The yield recommended at the end
is a proposal. Nothing here activates it.

## 1. What was run

All runs are 365 game days with the player inactive, unless marked otherwise. The calendar is the 8-day year (OD-21), so
365 days is about 45 calendar years.

| Run | Commit | Variants (both switches on unless stated) | Seeds |
|---|---|---|---|
| Actions 39580481791 | `cd68f58` | 0 control (switches off); 1.0, 1.5, 2.0, 2.5, 3.0 wheat a cell | 1-4. Seed 2 at 2.5 crashed (FARM-08A, since fixed) |
| Actions 39598992347 | `02ae508` | 0 control; shared only at 2.0; seasonal only; both at 1.5, 2.0, 2.5, 3.0. Adds the day-by-day herd log | 1-4 |
| Local, seed 1 | `02ae508` / `33013f3` | 40 days: control and both at 2.0 (herd log). 120 days: both at 2.0 | 1 |
| Local, seed 1 | `wip/b16-cattle` (the FARM-08B fixes) | 40 and 120 days: both at 2.0 | 1 |

`shared_wheat_yield` is the wheat a sown cell gives under the shared per-cell model (FSE-12). The player's crop gives 3.
The old field model gives 60 for a 66-cell field, about 0.9 a cell.

## 2. The yield matrix (Actions run 39580481791, `cd68f58`, before the FARM-08B fixes)

Values are per seed: seeds 1 / 2 / 3 / 4. Every column except the control has both switches on. Seed 2 at 2.5 crashed
on a script error since fixed as FARM-08A, so it has no values (—). Every completed job balanced its coin and item
ledgers (the job fails otherwise).

| Measure (seeds 1 / 2 / 3 / 4) | Control (old fields, no seasons) | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 |
|---|---|---|---|---|---|---|
| Starvation deaths | 0 / 0 / 0 / 0 | 20 / 21 / 20 / 5 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / — / 0 / 0 | 0 / 0 / 0 / 0 |
| Wheat harvested | 43,920 / 43,920 / 43,920 / 43,920 | 30,126 / 26,737 / 30,258 / 28,193 | 42,138 / 44,910 / 44,811 / 44,811 | 59,892 / 58,166 / 59,722 / 57,012 | 74,385 / — / 74,445 / 73,505 | 89,064 / 89,064 / 89,856 / 79,680 |
| Wheat consumed | 41,738 / 40,932 / 42,210 / 39,158 | 25,167 / 25,341 / 26,001 / 26,631 | 31,398 / 33,169 / 33,157 / 39,340 | 43,361 / 46,342 / 40,239 / 42,051 | 42,091 / — / 42,203 / 55,082 | 64,053 / 54,677 / 56,416 / 56,219 |
| Wheat sold away (exported) | 114 / 52 / 48 / 86 | 49 / 20 / 126 / 42 | 148 / 297 / 72 / 97 | 60 / 262 / 210 / 101 | 73 / — / 152 / 129 | 112 / 239 / 251 / 119 |
| Wheat held at the end (unsold or stored) | 2,791 / 3,659 / 2,385 / 5,399 | 5,633 / 2,099 / 4,854 / 2,243 | 11,315 / 12,167 / 12,305 / 6,097 | 17,194 / 12,285 / 19,996 / 15,583 | 32,944 / — / 32,813 / 19,017 | 25,622 / 34,871 / 33,912 / 24,065 |
| of it in the granary | 451 / 551 / 510 / 484 | 352 / 439 / 414 / 392 | 501 / 492 / 481 / 493 | 1,203 / 482 / 529 / 479 | 1,187 / — / 1,823 / 1,086 | 2,834 / 554 / 3,570 / 1,058 |
| Seed sown | 0 / 0 / 0 / 0 | 30,162 / 26,712 / 30,294 / 28,212 | 28,182 / 30,096 / 30,030 / 30,030 | 30,162 / 29,167 / 30,077 / 28,722 | 30,006 / — / 30,030 / 29,654 | 29,964 / 29,964 / 30,162 / 26,772 |
| Seed recovered | 0 / 0 / 0 / 0 | 29,766 / 26,377 / 29,898 / 27,833 | 27,852 / 29,700 / 29,634 / 29,634 | 29,766 / 28,903 / 29,681 / 28,326 | 29,610 / — / 29,634 / 29,258 | 29,568 / 29,568 / 29,832 / 26,440 |
| Seed bought from the caravan | 51 / 34 / 37 / 57 | 321 / 342 / 480 / 447 | 342 / 365 / 394 / 353 | 344 / 498 / 436 / 534 | 454 / — / 381 / 349 | 392 / 347 / 377 / 396 |
| Field cells left unsown for want of seed | 0 / 0 / 0 / 0 | 0 / 895 / 0 / 49 | 2,063 / 0 / 0 / 0 | 0 / 0 / 0 / 322 | 0 / — / 0 / 0 | 0 / 0 / 0 / 1,988 |
| Grain fed to the pens | 18,571 / 16,363 / 17,966 / 12,441 | 1,391 / 1,207 / 1,194 / 1,406 | 2,527 / 7,339 / 6,732 / 8,570 | 8,622 / 10,758 / 10,060 / 9,493 | 8,854 / — / 6,130 / 9,372 | 13,127 / 6,829 / 7,508 / 8,969 |
| Milk produced | 1,448 / 986 / 1,450 / 1,228 | 52 / 28 / 196 / 162 | 346 / 30 / 1,126 / 338 | 310 / 1,352 / 1,398 / 434 | 336 / — / 86 / 344 | 502 / 1,010 / 82 / 322 |
| Cows alive at the end | 5 / 0 / 5 / 1 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / 6 / 6 / 0 | 0 / — / 0 / 0 | 0 / 0 / 0 / 0 |
| Cows slaughtered | 119 / 79 / 115 / 102 | 5 / 2 / 13 / 14 | 8 / 2 / 94 / 28 | 14 / 107 / 114 / 35 | 15 / — / 8 / 28 | 21 / 83 / 8 / 26 |
| Wool produced | 281 / 289 / 285 / 271 | 32 / 38 / 18 / 30 | 37 / 284 / 50 / 284 | 286 / 288 / 261 / 299 | 302 / — / 183 / 275 | 277 / 281 / 282 / 277 |
| Meals missed: no food for sale | 188 / 126 / 63 / 30 | 16,264 / 26,487 / 31,193 / 12,695 | 104 / 59 / 44 / 45 | 134 / 64 / 47 / 46 | 107 / — / 59 / 20 | 143 / 64 / 77 / 54 |
| Meals missed: no money | 303 / 2,142 / 2,615 / 293 | 154 / 195 / 239 / 189 | 1,600 / 856 / 2,357 / 620 | 501 / 969 / 1,088 / 242 | 579 / — / 3,863 / 5,022 | 674 / 1,763 / 303 / 421 |
| Relief grain given | 2,070 / 1,778 / 2,855 / 883 | 2,090 / 2,272 / 2,809 / 2,048 | 2,121 / 1,112 / 2,829 / 1,913 | 1,303 / 1,220 / 2,285 / 1,338 | 1,823 / — / 1,585 / 2,159 | 1,305 / 2,114 / 2,090 / 2,213 |
| Food days in store at the end | 81.71 / 49.91 / 61.73 / 107.65 | 125.47 / 42.27 / 93.67 / 53.18 | 171.44 / 189.96 / 193.06 / 103.08 | 306.2 / 194.9 / 279.56 / 241.55 | 471.86 / — / 473.58 / 336.72 | 422.07 / 443.64 / 411.16 / 313.45 |
| Samples in famine (of 14) | 0 / 0 / 0 / 0 | 1 / 1 / 2 / 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / — / 0 / 0 | 0 / 0 / 0 / 0 |
| Farmers' wheat price at the end | 2 / 2 / 2 / 2 | 2 / 2 / 2 / 2 | 2 / 2 / 2 / 2 | 2 / 2 / 2 / 2 | 2 / — / 2 / 2 | 2 / 2 / 2 / 2 |

## 3. The measures the owner listed

- **Grain produced.** With seasonal fields, 1.5 a cell matches the old model's year (42,000-45,000 against 43,920). 2.0
  gives about 1.33 times as much, 2.5 about 1.7 and 3.0 about 2. At 1.0 the year falls to 27,000-30,000, about a third
  short.
- **Grain consumed.** The control eats 39,000-42,000 a year. At 1.0 the village eats only 25,000-27,000 and people
  starve. At 1.5 it eats 31,000-39,000 with no starvation. At 2.0 and above it eats 40,000-64,000, more than the control
  in part because the pens are fed better.
- **Grain sold away.** The caravan takes very little at any yield (20-297 a year). The surplus is not exported; it stays
  in the village.
- **Grain stored and unsold.** At the end of the year the village holds 2,400-5,400 in the control, 6,100-12,300 at 1.5,
  12,300-20,000 at 2.0 and 19,000-35,000 at 2.5-3.0. The granary holds only 450-3,600 of it. The rest is in farmers'
  packs and household chests.
- **Seed use and recovery.** A sown cell takes one seed and gives one back, so 26,700-30,300 seed is sown a year and
  about 99 % comes back. The farmers buy 321-534 seed a year from the caravan, against 34-57 in the control. Seed ran
  short in four runs: 2,063 field cells unsown for want of seed on seed 1 at 1.5, 895 on seed 2 at 1.0, 322 on seed 4 at
  2.0, and 1,988 on seed 4 at 3.0. Seed shortage is not tied to the yield. These runs do not show its cause; it
  is a question for the FSE-12 seed work.
- **Labour per harvest.** Under the shared model a 66-cell field takes 105.6 game minutes to sow (0.8 s a cell at 2 game
  minutes a second) and 435.6 to cut and plough (0.8 s + 2.5 s a cell), about 9 game hours in all, at any yield. The old
  model took 45 minutes to sow and 90 to cut, 2.25 hours. Labour does not scale with the yield; only the crop does.
- **Food security and starvation causes.** Only 1.0 starves people (5-21 deaths a seed, with 1-2 famine samples): the
  seasonal year is too small. From 1.5 upward nobody starves and the village never enters famine. Food days in store
  at the end rise with the yield: 50-108 (control), 103-193 (1.5), 195-306 (2.0), 314-474 (2.5-3.0). Meals missed for
  want of money vary widely by seed: control 293-2,615, 1.5 620-2,357, 2.0 242-1,088, 2.5 579-5,022, 3.0 303-1,763. Meals missed with no
  food for sale stay near the control (20-143) from 1.5 up. At 1.0 they reach 12,700-31,200.
- **Manor viability.** The six manor fields are sown in every season but winter, except the
  cells left unsown for want of seed (above). The granary is filled by the
  existing manor rules and holds 450-3,600 at the end. The manor's grain is never short from 1.5 upward. Relief grain
  given out is similar at every yield (880-2,860 a seed).
- **Family farm viability.** Not measured by these runs. The family farm plots (FARM-01..05) are a separate workstream.
  The farmers here are the manor's.
- **Market demand and prices.** The farmers' asking price for wheat ends at 2 in every run, control included. That is
  the price floor (section 4): every farmer holding 14 or more wheat asks the floor price, so a larger harvest cannot
  lower the price further. Demand does not grow with the supply: the caravan barely buys and the village eats what it
  needs.
- **Livestock feed and milk.** The control feeds the pens 12,400-18,600 wheat a year and makes 990-1,450 milk. With
  both switches on the pens get 1,200-1,400 at 1.0, 2,500-8,600 at 1.5 and 6,100-13,100 at 2.0-3.0, and milk falls to
  30-1,400. Cows alive at the end: control 5 / 0 / 5 / 1, and with both switches on, none on every run except seeds 2
  and 3 at 2.0. Section 5 explains the herds and the defects found.
- **Seasonal timing.** No field is sown in winter. A field sown in late autumn waits through winter. The grain therefore
  comes in bursts, about every 6-8 game days, and the gaps between harvests are where the pens ran dry (section 5).

## 4. The wheat price floor (FARM-08C): an economic finding, no rule changed

`World.sell_price_at` sets a seller's asking price as the item's value times a multiplier:

`m = clamp(1.5 - 0.05 x stock - 0.02 x min(nearby supply, 25), price_min + 0.2, price_max)`

`price_min` is 0.6, so the floor is 0.8. Wheat is worth 3, so the floor price is round(3 x 0.8) = 2. A seller holding
one wheat asks round(3 x 1.45) = 4. The multiplier reaches the floor at 14 held (1.5 - 0.05 x 14 = 0.8), and sooner when
other sellers nearby hold wheat. Wheat therefore sells for 2-4 coins, and any farmer with 14 or more asks 2.

In every FARM-08 run, control included, the farmers' price at the end of the year is 2. A farmer after a harvest holds
far more than 14, so the price is at the floor for most of the year. More grain cannot lower it, and scarcity shows only
when a seller is nearly empty.

**Effects to weigh before any change (not changed, per the owner's directive):**

- The floor protects farmers' income in a glut. Without it, a 2.0-3.0 yield would drive grain towards 0-1 coin.
- It also blunts the market signal. Buyers cannot tell a glut from a normal year, so nothing in the price tells
  households or the caravan to buy more when grain is plentiful.
- It sets the cost of animal feed. A cow eats 4 wheat a day (8 coins at the floor) and gives 2 milk (worth 3 each, sold
  to the cook for about 2 each). So a herd fed on bought grain always costs its keeper more than it earns (section 5).
- Any change to `price_min` moves every item's floor, not just wheat's. An evaluation would need runs of the whole
  economy.

## 5. The cattle investigation (FARM-08B)

### 5.1 How the herd works

- A village pen starts with a bull, a cow and a juvenile heifer: three cattle, the same on every seed.
- A cow eats 2 wheat a meal from the trough, about two meals a day. The keeper counts 4 wheat a day for each animal.
  A cow at zero hunger loses health and dies about 43 hours after its last meal.
- A well-fed adult cow gives 2 milk a day. Only adults in their prime, not the elderly, breed and give milk.
- A cow calves once every 6 days (0.75 years). A calf is grown after 6 days.
- The elderly stage starts at 96 days (12 years). Death from old age comes between 120 and 160 days (15-20 years).
- The pen holds 6 cattle; the keeper keeps 2 cows as breeding stock.
- The pens have no pasture: the animals eat only from the trough.
- The keeper is a farmer of one of the manor fields. Feed comes three ways:
  - when that field is cut, the harvester puts four days' feed in the trough;
  - the keeper takes it from the household chest;
  - the keeper buys it from a farmer or the food merchant.
- With no feed to be had and less than a day's feed in the trough, the keeper culls one animal beyond the breeding
  stock.

### 5.2 Defects found and fixed (branch `wip/b16-cattle`)

Each is a rule failing its own stated purpose. None adds animals, feed, coins or births.

1. **All-or-nothing feed lot (parity).** The keeper looked for one seller who could spare a whole three-day lot beyond
   their own reserve, and only if the keeper could pay for all of it. The sale itself (`buy_from`) sells a part lot, and
   the player can buy any number. Grain for sale in smaller amounts, or a keeper able to pay for a day's feed but not
   three, ended in a cull. **Fix:** the keeper now buys as much of the lot as the best seller can spare and the keeper
   can pay for (`NPCBrain._keeper`).
2. **Grain shut in the family chest while a keeper needed it.** Since FSE-18 a producer keeps for sale only its own
   reserve and what the cook and the food merchant still want; the rest goes into the family chest, where nobody can
   buy it. The keeper's demand was not counted. Measured on seed 1, both switches at 2.0, 40 days: of the 34 hours a cow
   went hungry while the keeper had no grain, 30 had grain only in other households' chests (300-900 wheat). Two cows
   starved on day 26 while 670 wheat lay in chests and 241 in the granary. **Fix:** a farmer also keeps in hand the feed
   each keeper of another household lacks to hold its four-day reserve (`NPCBrain.feed_want`, counted in `_sale_stock`).
   The household's own food comes first, as before.
3. **The elderly counted as breeding stock.** When short of feed the keeper culled beyond the breeding stock, but it
   counted the elderly, who no longer breed, as breeding stock. It culled the calves that would have replaced them, and
   the herd died of old age with no successor. The control on seed 2 shows this: 32 cattle were culled for lack of
   feed, the last on day 197, which left no young and two of the three adults elderly; the three adults then died of
   old age on days 232, 257 and 316, and the pen was empty from day 316. **Fix:** the elderly go before the young; spare males and cows beyond
   the keep go first, as before (`Fauna.surplus`).

Tests: `game/tests/herd_test.gd` (19 checks; 10 of them fail on the old code). Local verification on seed 1 with both
switches at 2.0, from the same start. The 40-day "after" run had fixes 1 and 2 only; no animal is elderly before day 96,
so fix 3 cannot act in it. The 120-day runs compare `33013f3`'s code with all three fixes.

| Seed 1, both switches at 2.0 | Before (`33013f3`) | After (`wip/b16-cattle`) |
|---|---|---|
| 40 days: cow-hours hungry with an empty trough | 54 | 0 |
| 40 days: cows starved | 2 (day 26) | 0 |
| 120 days: cows at the end | 1 (a lone bull, from day 26) | 3 (bull and two cows, breeding) |
| Calves born | 8 by day 26; none possible after (a lone bull) | 39 in 120 days |
| 120 days: milk made | 84 (none after day 26) | 474 |
| 120 days: starvation deaths (people) / ledgers | 0 / balanced | 0 / balanced |

The control (switches off), seed 2, 120 days, from the same start, as a check that the fixes do no harm:

- **Before** (run 39598992347): 40 calves, 8 culls for no feed, 1 bull, 2 cows and 1 calf at day 120.
- **After:** 38 calves, 3 culls for no feed, 1 bull, 2 cows and 2 calves, 474 milk. No starvation (people or cattle),
  and the ledgers balanced.

On this seed the control's herd died out on day 316 (section 5.4). Only a 365-day run can show whether the elderly
fix prevents that (section 7).

### 5.3 What remains, and is legitimate

After the fixes the herd on seed 1 still has culls for lack of feed: 21 in 120 days. Almost every one
(175 of 183 "no feed" decisions) had grain for sale in the village while the keeper could not pay for one wheat. The
cow keeper's coins fall to 0-5 from about day 5 and stay there. The cause is the herd's economics, not a failing rule:

- At the floor price a cow costs 8 coins a day in grain. A milking cow earns about 4 a day in milk sold to the cook.
  The bull and the calves earn nothing until they are slaughtered.
- In the old model the keeper's field is cut every 2 game days and each cutting fills the trough with four days' feed,
  so the herd lives almost wholly on its own field's grain.
- With seasonal fields the field is cut about every 6-8 days. The four days' feed from a cutting leaves a gap of 2-4
  days, which the keeper must buy, and cannot afford.

This is a legitimate outcome under WDR-022: the keeper does not own enough grain to carry the herd between harvests,
and the herd shrinks to its breeding stock until the next harvest. The breeding stock survives and breeds, and the
herd is no longer lost to old age. The chicken and sheep keepers show the same pattern ("no coins": 46 and 10 hungry
hours in 120 days).

### 5.4 The nine points, per seed

Sources (before the fixes):

- **Control and shared-only:** run 39598992347 (`02ae508`), full 365-day herd logs, seeds 1-4.
- **Both switches at 1.0-3.0:** run 39580481791 (`cd68f58`), end-of-year counts.
- **Seed 1, both switches at 2.0:** local herd logs.

Seasonal-only herd logs are from the same run. In those runs the whole village ran out of grain: the granary was
empty from about day 18, farmers and chests held almost nothing, the village was in famine, and 12-50 people starved a
seed. The cattle there died of a real shortage (legitimate). On seed 1 the last cows starved on day 43, leaving a lone
bull until it died of old age on day 139. The both-switches herd logs of run 39598992347 were still queued when this
was written; the lead adds them. Section 7 lists
the 365-day runs that verify the fixes.

1. **Starting cattle, by seed.** Three on every seed and in every variant: a bull, a cow and a juvenile heifer. The pen
   holds at most 6.
2. **Births and deaths over 365 days.**

   | Seeds 1 / 2 / 3 / 4 | Calves born | Slaughtered as surplus | Culled for no feed | Starved | Old age | Cows at the end |
   |---|---|---|---|---|---|---|
   | Control | 118 / 64 / 55 / 119 | 115 / 32 / 39 / 115 | 0 / 32 / 16 / 2 | 0 / 0 / 3 / 0 | 0 / 3 / 0 / 0 | 6 / 0 / 0 / 5 |
   | Shared only, 2.0 | 115 / 120 / 119 / 116 | 109 / 114 / 104 / 101 | 3 / 3 / 12 / 12 | 0 | 0 | 6 / 6 / 6 / 6 |
   | Seasonal only (old fields) | 14 / 17 / 13 / 12 | 0 / 2 / 1 / 0 | 9+5 famine / 5+10 / 6+6 / 4+8 | 2 / 3 / 3 / 3 | 1 / 0 / 0 / 0 | 0 / 0 / 0 / 0 (empty on days 139 / 56 / 50 / 41) |
   | Both, 2.0 (`cd68f58`, end counts) | — | 14 / 107 / 114 / 35 slaughtered in all | | | | 0 / 6 / 6 / 0 |

   Seed 1 with both at 2.0 (local log): 8 calves by day 26; 9 culled for no feed from day 9; 2 cows starved on day 26.
   That left a lone bull, which cannot breed, alone in the pen to day 120.
3. **Causes and timing of deaths.**
   - **Surplus slaughter** is the normal end of most cattle in a healthy herd: about one a calving once the pen nears its
     cap.
   - **Control seed 2:** culls for no feed from day 8 to day 197, which took the young. The elderly adults then died of old
     age on days 232, 257 and 316, and the pen was empty from day 316. This is the elderly defect (5.2 item 3).
   - **Control seed 3:** culls for no feed from day 5 to day 171. Three cows starved on day 172 while farmers held 276
     wheat and the households' chests 815. This matches the chest and part-lot defects (5.2 items 1-2). That log predates
     the breakdown of reasons, so the match is inferred.
   - **Seed 1 with both switches on:** culls from day 9 and starvation on day 26, with 670 wheat in chests.
   - **Old age** ends a cow at 120-160 days. It ends the herd only when nothing younger has been kept to replace it.
4. **Feed available against feed eaten.**
   - The control's pens eat 13,400-17,800 wheat a year (all kinds), out of 43,920 grown.
   - Shared-only pens eat 12,900-18,400.
   - With both switches at 2.0 the pens eat 6,100-10,800. On seed 1 the cow trough ran dry on days 9-10 and 24-26 while
     the village held 300-1,000 wheat outside the farmers' packs: 241-306 in the granary, 270-900 in households' chests.
   - Feed existed, but the keeper could not reach it: chests, and whole-lot buying.
5. **Can cattle reach their feed?** Yes. A pen animal eats from its own pen's trough whenever it is hungry and the
   trough holds a meal (`Fauna._eat`). Where it stands does not matter; the walk to the gate is only shown. There is no
   path to fail. The failures were all on the supply side: an empty trough.
6. **Seasonal and winter effects.**
   - The old model has no seasons for fields. Its no-feed culls fall across all four calendar seasons alike.
   - With seasonal fields nothing is sown in winter, growth halves in autumn, and the keeper's field is cut about every
     6-8 days instead of every 2. The trough's four days' feed from a cutting therefore runs out before the next.
   - The herd log shows the troughs empty in the days before each cutting, whatever the calendar season. The cattle have
     no winter behaviour of their own.
7. **Reproduction eligibility and whether it happens.**
   - A cow calves when well fed, in her prime, with a bull in his prime, and once every 6 days. Calving is reduced as
     the pen nears its cap.
   - **Healthy herds** breed throughout: about 115-120 calves a year in the control on seeds 1 and 4, and in shared-only
     on all seeds.
   - **Failing herds** stop breeding for one of two reasons. Either the last cows starve (seed 1 both, seed 3 control),
     or the only adults are elderly (seed 2 control). The herd log records ready cows (`ready_f`) and whether a mate is
     present (`mate`) every day.
8. **Labour, scheduling or pathfinding failures in animal care.**
   - **Labour and pathfinding:** none found. The keeper was never absent (`no_keeper` 0 hours).
   - **Holding grain but not feeding:** 4 hungry hours in 40 days (seed 1, both at 2.0), the time a keeper takes to
     fetch and carry feed.
   - **Asleep:** 16-22 hungry hours. These most likely follow from an empty trough the evening before, not from a separate failure.
   - **Scheduling defects:** the whole-lot rule and the chest rule. They are fixed (5.2).
9. **Why the old model keeps cattle on three seeds and the new one loses them.**
   - The old model's keeper field is cut every 2 days and each cutting fills the trough, so the herd lives on its own
     field. Even so, the control lost its herd on seeds 2 and 3, through the elderly and chest defects.
   - Shared farming alone keeps the herd on all four seeds: it is the same harvest rhythm with more grain.
   - Seasonal farming alone (old fields) loses the herd on every seed by day 41-139. The village's whole grain year is
     about a quarter short, and people starve too. This is legitimate scarcity, not a care failure.
   - Seasonal farming stretches the gap between cuttings to 6-8 days. In the gap the keeper must buy, and the defects
     stopped the keeper buying when grain was there. With the fixes the herd survives the gaps on seed 1, shrinking to
     its breeding stock in a gap and growing again after each harvest.
   - What remains is legitimate (5.3): the keeper cannot afford bought feed.

### 5.5 Design questions for the owner (not changed)

1. **Does the manor sell or lend grain from the granary to keepers?** No approved rule says it does. On seed 1 the
   granary held 82-400 wheat while cows were culled for want of feed. Selling it would be new manor behaviour.
2. **How much of a cutting goes to the pen?** The harvest rule fills the trough with four days' feed, fixed when
   cuttings came every 2 days. With seasonal fields the next cutting is 6-8 days away. "Until the next harvest" would
   change who eats the grain.
3. **Pasture or hay?** Pen animals eat only grain. Grazing in the pens, or hay from the fields, would let a herd live
   through a grain gap. This is a new mechanic.
4. **Herd economics.** At the price floor a cow costs about twice what its milk earns. Whether milk should be worth more,
   or a keeper should hold fewer animals, is a balance choice. It interacts with the price floor (section 4).

## 6. Recommended yield (for the owner's approval; the switches stay off)

**Recommendation: 2.0 wheat a sown cell, with both switches together, once the FARM-08B fixes are verified over 365
days on four seeds** (section 7). This is provisional on those runs.

Reasons:

- **Food security and seasonal supply.** 1.0 starves the village on every seed. 1.5 is the smallest yield with no
  starvation and no famine. But its margin is thin: 2,063 unsown cells on seed 1, more meals missed for want of money
  than at 2.0 on three seeds of four, and its harvest only equals the old model's, with a winter gap the old model did not have. 2.0 carries
  every seed through the winter gap with no starvation and 195-306 food days at the end.
- **Livestock survival.** Before the fixes only 2.0 kept cows on any seed (6 on seeds 2 and 3). After the fixes the
  herds no longer die of the defects at any yield. What remains depends on the keeper's grain between cuttings, which a
  larger crop helps only through prices (already at the floor).
- **Seed sustainability.** Seed recovery is about 99 % at every yield. The shortfalls come from where the seed is held,
  not from the yield.
- **Manor production, market and balance.** Above 2.0 the extra grain is not eaten or exported. 2.5 and 3.0 end the
  year holding 19,000-35,000 unsold, with the price already at its floor. 2.0 is the smallest yield with a safe margin
  and the least glut.
- **Parity.** The player's crop is 3 a cell. Choosing 2.0 for the manor's fields under FSE-12 means either the player's
  crop also moves to 2.0 (one rule for everyone, FSE-12 option (b)) or the gap is explained. This is part of the owner's
  decision.

## 7. Verification still to run (the lead dispatches; 365 days, seeds 1-4, on `wip/b16-cattle` or its staging merge)

- **Variant 0:** control, switches off. Checks that the fixes do not harm the old model, and that seeds 2 and 3 no
  longer lose their herd. The determinism and sim-gate baselines change with the fixes.
- **Variant 1:** both switches at 1.5.
- **Variant 2:** both switches at 2.0.
- **Variant 3:** both switches at 2.5.
- **Variant 4:** shared farming only at 2.0.
- **Variant 5:** seasonal farming only.

## 365-day variant results (Actions run 39618523947, commit `dbbb66a`, read 2026-10-21)

Twenty-four 365-day runs (seeds 1-4 by six configurations). **Integrity:** every run exited 0 with 0 script errors, coin
leak 0, no item leak, no coin or holder mismatch, and the herd counts reconcile (start + born - slaughtered - starved -
old age = end). Villager starvation deaths: 0 in all 24. Leaks, alive and errors come from each job's printed run
summary; the job logs echo only the last 30 lines of `sim.log` (the artifacts could not be downloaded through the proxy).

Every run starts with 3 cattle. "No feed" counts the keeper's failures to buy feed he could afford.

| Configuration | Seed | Alive | Food days | Cattle at end | No feed |
|---|---|---|---|---|---|
| control (switches off) | 1/2/3/4 | 139/123/105/146 | 286/282/346/286 | 5/6/6/5 | 59/21/46/1 |
| manor + seasonal, yield 2.0 | 1 | 114 | 586 | 6 | 1 |
| | 2 | 145 | 553 | 0 (by day 169) | 226 |
| | 3 | 148 | 456 | 0 (by day 49) | 146 |
| | 4 | 132 | 364 | 5 | 345 |
| manor + seasonal, yield 1.5 | 1 | 132 | 330 | 6 | 357 |
| | 2 | 162 | 381 | 0 (by day 123) | 123 |
| | 3 | 136 | 245 | 6 | 529 |
| | 4 | 115 | 179 | 5 | 454 |
| manor + seasonal, yield 2.5 | 1 | 109 | 797 | 0 (by day 113) | 76 |
| | 2 | 120 | 623 | 5 | 164 |
| | 3 | 104 | 817 | 0 (by day 218) | 346 |
| | 4 | 161 | 489 | 5 | 466 |
| manor only, yield 2.0 | 1/2/3/4 | 138/142/171/107 | 718/780/682/986 | 4/6/5/5 | 0/27/44/39 |
| seasonal only | 1 | 136 | 211 | 5 | 834 |
| | 2 | 150 | 189 | 5 | 362 |
| | 3 | 147 | 231 | 0 (by day 240) | 447 |
| | 4 | 121 | 263 | 5 | 514 |

**Cattle decline (FARM-08B question).** Five of 24 herds died out, all with `seasonal_village_farming=1`, at yields 1.5,
2.0 and 2.5 alike, so the yield does not explain it (the earlier partial reading that 1.5 was fine was wrong: seed 2 lost
its herd at 1.5). Mechanism in every case: the keeper runs out of coins (0 at the end on seeds 2 and 3 at 2.0) while grain
is plentiful (seed 3 at 2.0, day 49: farmers 1,780 wheat, chests 1,665), cannot buy one unit at price 2, culls for want of
feed down to the breeding stock (`slaughter_no_feed_cow`), and the breeding stock then starves or ages out; in two runs a
feed cull took the old bull first (old before young, by design) and the cows aged out. Classified a **legitimate
economic outcome** (WDR-022), not a defect: every loss has a recorded cause and the ledgers reconcile.

**Not yet established:** why seasonal farming drains the keeper's purse ("no feed" 76-834 a year with it, 0-59 without);
tracing the keeper's daily income and spending would settle it. Also noted, unverified by the lead: most surviving herds
produced about 1,450 milk with 930-1,410 unsold at day 365, and the season label appears to change about every 2 days in
these runs. No recommendation is made here; the switches stay off until the owner decides.

## Keeper diagnostic (owner directive 2026-10-21, `docs/directives/2026-10-21_farm08_keeper_diagnostic.md`)

One probe run, read-only hooks, on commit `dbbb66a`: seed 3, `shared_manor_farming=1 seasonal_village_farming=1
shared_wheat_yield=2`, 55 days; it reproduces the reference run exactly (same fingerprint, herd gone on day 49, farmers
1,780 wheat, chests 1,665). No switches-off run was needed. Probe and full trace kept outside the repository (lead's
scratchpad `farm08diag/`).

**Confirmed facts.**
- The keeper (NPC 39, a farmer) started with 28 coins and held 0 after buying his last 7 wheat on day 7 (09:00); 0-16
  after, 0-2 from day 22. Every coin change was a trade (tax, rent, wages and household transfers fall on the household's
  richest member). Feed is bought from the keeper's own coins only (`npc_brain.gd` around line 1340).
- Account to day 49: income 213 (milk 70 units for 138, cull meat 49, wheat seed 24, hide 2); spending 241 (feed wheat
  99 units for 198 at price 2 in 22 purchases, firewood 21, planks and stone 10, seed 6, bread and ale 6); 28 + 213 - 241 = 0.
  The household's coins fell from 130 (day 0) to 7 (from day 24).
- Milk: 176 produced, all collected, 70 sold (steady to day 19, sporadic after); up to 27 held unsold with 0 coins
  (`HOUR d47 h09 coins=0 milk=27`); villagers ate 99 raw; cheese making stalled (`used_milk` 33 from day 21 to 40). Even all
  176 sold at 2 buys about 176 wheat; the herd ate about 800.
- Feed was physically available and reachable (4-11 farmers or food merchants awake with 66-2,192 spare wheat at price 2;
  22 successful purchases from three sellers) but not affordable: 143 of 146 "no feed" events were "no coins".
- Sequence: coins 0 on day 7; first no-feed day 8; culls to the breeding stock days 9-11; days 11-47 each cutting of his
  field fills the trough with a fixed 4 days of feed (`npc_brain.gd:2251-2253`); cuttings on days 4, 10, 14, 19, 25, 28,
  34, 38, 43, 49 (gaps 3-6 days; the trough also emptied before the cuttings of days 25 and 34); trough empty day 47 noon;
  the bull and both cows starved by day 49 06:00; his field was cut on day 49 16:00 (124 wheat to him), too late. The last
  gap was 6 days because the field sown on day 43 grew at half rate in autumn and not at all in winter.
- Seasons: two game days a season is the owner's design (`balance.json` `year_days` 8, `season_days` [2,2,2,2], B8-029,
  owner-approved 2026-10-19, `docs/DECISIONS.md`), read by `Life.season_index`; the harness's `--set` cannot change it.
  Not a test acceleration and not a defect.

**Classification.**
1. Legitimate economic consequence: a keeper who cannot pay gets nothing; the herd is culled to breeding stock and
   starves across a long gap. No rule failed and nothing leaked.
2. Economic balance concerns: (a) a herd costs about 24-48 coins a day in grain at the floor price and earns at most about
   8; (b) a cutting fills the trough with a fixed 4 days of feed while seasonal fields are cut 3-6 days apart; (c) milk
   demand saturates (70 of 176 sold, cheese stalled); (d) the whole household impoverished.
3. Implementation defect: none established (ruled out: the switch blocking sales, unreachable markets, a hidden drain, the
   keeper's buying logic).
4. Unresolved: (a) **crop allocation** - the whole crop goes to whichever farmer finishes the cutting (`take_crop(f, 1 << 30)`,
   `npc_brain.gd:2241-2243`) though `world.gd:2166-2167` calls it "the farmers' who work it"; the keeper spent about 72
   hours harvesting and received grain once (day 49). Whether this is intended or a defect is not settled; the co-farmer
   is unverified. (b) Why the cook stopped making cheese.

**Smallest corrective options (none applied; owner decision):** fill the trough until the next expected harvest under
seasonal fields; size the herd to the keeper's grain or raise milk's value; investigate the cheese outlet, then milk caps
or another buyer; let feed purchases draw on the household purse as meals do, or granary sales to keepers; first log who
cuts each field and, if the crop is meant to be shared, split it among the field's workers or reserve the keeper's share.

## Crop allocation (owner request 2026-10-22: read-only, code inspection plus the existing keeper trace; no new run)

**Confirmed from code (staging, the same rules as `dbbb66a`):**
1. *Ownership and authority.* Every field is the manor's; "its crop the farmers' who work it" (`world.gd` comment above
   `player_harvest`). The workers of a field are the living farmers whose `workplace` is it (`World.field_workers`), set
   round-robin at world creation (`population.gd:183-184`) or when a manor hand takes over an untended field
   (`npc_brain.gd:861`); fields have no lease or owner record of their own (OD-23 concerns rent, not division). Anyone else
   taking crop is theft, except the player hired for the harvest (`Quests.hired_harvest`).
2. *Who labours.* Every worker of a ripe field plans the same cutting (`npc_brain.gd:1252-1255`: `work(cut, "harvest")`), so
   co-workers cut side by side for the whole cutting time.
3. *Who receives.* The worker whose cutting action completes first takes the entire crop (`take_crop(f, 1 << 30)`,
   `npc_brain.gd:2241-2243`) less seed kept back; the field becomes tilled, so the others' actions find nothing
   (`field_cuttable` false, the action returns false) and they get no share. From the harvester's crop: the pen of any
   keeper working the same field is fed up to 4 days (1 in famine) first (`npc_brain.gd:2246-2252`, comment "the farm's
   livestock is fed from the farm's crop ... before anything is sold"), then the harvester's household pantry is topped up
   to 10, and the rest stays with the harvester to sell.
4. *Trace evidence (keeper diagnostic, seed 3):* the keeper (NPC 39) was "harvesting wheat" at the cuttings of days 4 and 10,
   held no wheat after them, and his trough jumped (36 to 64 on day 4, 7 to 48 on day 10): the co-worker who finished first
   took the crop and fed his pen; the keeper later bought wheat from Joan Oakley (farmer) on days 14 and 15.

**Owner decisions and documents checked:** OD-23 (rent and crop share to the manor: the lease answer, nothing on division
among co-workers), FSE-12/FSE-13 (one model, seasonal fields; nothing on division), the food-security audit ("farmers keep the
whole crop", plural), the PAR and FSE directives (real labour, real accounting). **No decision or design text says the first
farmer to finish takes everything**, and none sets a division rule.

**Classification.** The "first to finish takes all" rule is not an approved design: it contradicts the stated collective
ownership ("the farmers' who work it") and wastes the co-workers' completed labour (an action that does nothing). It is
classed as an **implementation defect in an unspecified area** - a missing division rule - rather than a legitimate outcome.
It conserves goods (nothing created or lost), it applies with both farming switches off (the same `take_crop` call), and the
keeper's herd is not deprived by it at a cutting (the field's crop feeds the pen first, by design); its effect on the keeper
is that his labour earns him no grain to sell or keep, only the 4 days of feed. How the crop should be divided is an owner
decision; no change has been made.

**Options (none applied):** (a) divide the crop among the field's workers present at the cutting, equally; (b) divide it in
proportion to the cutting time each put in; (c) keep one taker but rotate it among the field's workers; (d) confirm the
present rule as intended (then record it in the design). In every case the pen feeding stays first and the seed kept back
stays with the field's seed rule.

**Answered (owner, 2026-10-22, `docs/directives/2026-10-22_farm08_q_crop_decision.md`): FARM-08-Q-CROP option B,
proportional harvest sharing.** The crop goes to the farmers who cut it in proportion to their cutting work, after the
seed kept back and the pen's feed. Implemented on `wip/farm-cropshare` (FARM-CROP-01, `132960a`), not merged into Build 17.
