# Trader sustainability and the village coin reconciliation (X20-TRADER-PAY-INV)

Analysis only. Owner decisions X20-TRADER-PAY option A (`docs/directives/2026-10-30_x20_trader_pay_decision.md`) and its final
form (`docs/directives/2026-10-30_x20_trader_pay_final_decision.md`): the 85% trader reserve and the compensation rules stay as
they are. No balance change is made or proposed for implementation here. Branch `wip/x20-trader-inv`, analysis date 2026-10-31.

## Evidence used

| Source | What it is |
|---|---|
| Actions run 41115998996 (`4611d86`, Build 24) | Baseline, seeds 1 and 2, 60 days: checkpoint lines, village currency holders, settlement coins, treasury, trader |
| Actions run 41133027134 (`108d252`) | Closure of idle traders without reopening (Finding 1 only) |
| Actions run 41139763023 (`3702566`) | Closure plus reopening (X20-SETTLE-REOPEN): the subject of this analysis |
| Local `economy_sim.gd --trader-diag` (`3702566` + the read-only diagnostic of this branch), seeds 1 and 2, 60 days | Daily trader books (till, reserve, wages paid, stock value, caravan, road, outside and regional flows), each household that ever worked a settlement's trade (coins, weekly income, rate, low-income streak, stay, trade, pantry), settlement holders (treasury, household purses, business tills) and goods and coins in transit |

**The diagnostic changes nothing.** The local diagnostic runs end with the same fingerprints as the Actions run on the same commit:
seed 1 `1aa863d6e48d33f75a34ac110197a99b`, seed 2 `9e801ad7320d0ea35079e1043d0639e7`. That is byte-level equality of the
village state at day 60, so the diagnostic reads only. It only reads fields (no price cache, no RNG, no state-changing call); the
code is `_trader_diag` in `game/tests/economy_sim.gd`, behind `--trader-diag`, which is off by default.

## 1. Coin reconciliation (first)

**Lower village coins are not lost coins.** The world's coins, village plus the five settlements plus transit and escrow, are
the same at day 60 as at day 0 in every run, to the coin. The village holds less only because fewer coins crossed from the
settlements into the village. Those coins are still in the settlements.

| Seed 1, day 60 | Build 24 | Closure only | Closure + reopening |
|---|---|---|---|
| Village coins (`World.total_coins`, leak 0) | 5429 | 3995 | 4191 |
| Settlements' coins | 6829 | 8263 | 8067 |
| Settlement coins in escrow / goods in transit | 0 / none | 0 / none | 0 / none |
| **World total** (start 3009 + 9249) | **12258** | **12258** | **12258** |
| `coin_sources`, the village's net inflow from outside (external in − out) | 2420 (4440 − 2020) | 986 | 1182 (2679 − 1497) |

| Seed 2, day 60 | Build 24 | Closure only | Closure + reopening |
|---|---|---|---|
| Village coins | 5236 | 3848 | 4083 |
| Settlements' coins | 7295 | 8683 | 8448 |
| Settlement coins in escrow / goods in transit | 0 / none | 0 / none | 0 / none |
| **World total** (start 2966 + 9565) | **12531** | **12531** | **12531** |
| `coin_sources` | 2270 (3535 − 1265) | 882 | 1117 (2064 − 947) |

The village's shortfall against Build 24 (seed 1: 1238; seed 2: 1153) equals the fall in `coin_sources` exactly, and equals the
settlements' gain exactly. The cause is that the caravan bought less from the village and sold it less: seed 1 external in
−1761, out −523; seed 2 in −1471, out −318. Exports fell (seed 1 iron bars 160 → 86, planks 293 → 252; seed 2 planks 264 → 73).

**Where the 1238 / 1153 coins sit.** Holders below, Build 24 → reopening, day 60.

*Village side* (`currency.holders`):

| Holder | Seed 1 | Seed 2 |
|---|---|---|
| Villagers' purses | 2965 → 2321 (−644) | 3215 → 2459 (−756) |
| Chapel fund | 2110 → 1730 (−380) | 1753 → 1434 (−319) |
| Manor treasury | 175 → 4 (−171) | 114 → 1 (−113) |
| Contract reserves | 0 → 0 | 40 → 0 (−40) |
| Courier booths | 18 → 0 (−18) | 20 → 19 (−1) |
| Bandits | 27 → 0 (−27) | 2 → 1 (−1) |
| Stall tills | 34 → 36 (+2) | 72 → 76 (+4) |
| Loot | 80 → 80 | 0 → 73 (+73) |
| Player | 20 → 20 | 20 → 20 |
| **Total** | **−1238** | **−1153** |

*Settlement side* (per settlement: coins = treasury + trader's till + the rest, i.e. households and other businesses' tills):

| Settlement | Seed 1: Build 24 → reopening | Seed 2: Build 24 → reopening |
|---|---|---|
| Wulstead | 2024 → 2745 (+721): treasury +402, trader −119, rest +438 | 1742 → 1922 (+180): treasury +147, trader −255, rest +288 |
| Netherton | 172 → 349 (+177): treasury +28, trader −74, rest +223 | 351 → 725 (+374): treasury +161, trader −16, rest +229 |
| Garton | 1724 → 1057 (−667): treasury −162, trader −344, rest −161 | 1518 → 1297 (−221): treasury +68, trader −62, rest −227 |
| Higham | 2284 → 2686 (+402): treasury +483, trader −204, rest +123 | 2654 → 3279 (+625): treasury +535, trader −347, rest +437 |
| Bourton Abbas | 625 → 1230 (+605): treasury +170, trader −105, rest +540 | 1030 → 1225 (+195): treasury +8, trader −4, rest +191 |
| **Total** | **+1238** | **+1153** |

At day 60 of the reopening run, the settlements' 8067 (seed 1) is 1945 in treasuries, 4865 in household purses and 1257 in
business tills (188 of it traders'). For seed 2 the 8448 is 1980 treasuries, 5429 household purses and 1039 tills (154 traders').
Each settlement's breakdown closes to the coin on every day of both runs (305 daily rows each, 0 mismatches). Build 24's logs record only coins, treasury and
trader per settlement, so "rest" is not split further for the baseline.

**Mechanism.** A trader that closes hands its till to its council (`_close_business`), which is why treasuries rose. A closed
trader neither sells to nor buys from the caravan, so the settlement keeps the coins it would have spent on village goods, and its
households keep them too.

**Verdict:** conserved, no accounting defect. The difference is a genuine economic effect: less trade across the village boundary.

## 2. Why the traders' households do not sustain themselves

### 2a. Per trader (each period it was open)

Table notes:
- **Sales**: caravan sales to the village (less horse sales, which go to the farm) and road sales to other traders.
- **Local net**: the residual of the till's change after the known flows. It is local sales to households less purchases from local
  producers.
- **Purchases**: from the village caravan, from other traders on the road, and outside payments (the courier service; no
  settlement-to-settlement food purchase happened in these runs: transit and escrow were empty at the end of every day).
- **Operating result**: the change in till plus stock value, plus wages paid. It is what the trade earned before paying anyone.
- **Withheld**: the part of the wage shortfall (10 a worker a day) the till could have paid but kept back as its reserve.

| Seed | Trader, open days | Opening till / reserve | Days at/below reserve | Sales: caravan + road; local net | Purchases: village, road, outside | Operating result | Wages due / paid | Withheld by reserve |
|---|---|---|---|---|---|---|---|---|
| 1 | Wulstead d0–34 | 300 / 255 | 25 of 34 | 624 + 296; −263 | 421, 81, 44 | −12 | 470 / 123 (26%) | ~393 |
| 1 | Netherton d0–27 | 130 / 110 | 24 of 27 | 41 + 12; +339 | 238, 28, 125 | +8 | 200 / 47 (24%) | ~179 |
| 1 | Garton d0–21 | 200 / 170 | 18 of 21 | 0 + 151; +119 | 266, 60, 40 | +62 | 140 / 47 (34%) | ~130 |
| 1 | Higham d0–56 | 360 / 306 | 39 of 56 | 688 + 66; +955 | 580, 312, 490 | −149 | 840 / 310 (37%) | ~672 |
| 1 | Bourton d0–21 | 160 / 136 | 19 of 21 | 5 + 0; +114 | 84, 26, 0 | +39 | 140 / 33 (24%) | ~120 |
| 1 | **Garton reopened d49–60** | 173 / 80 | 11 of 12 | 0 + 0; +39 | 114, 18, 0 | +90 | 120 / 0 (0%) | ~120 |
| 1 | **Wulstead reopened d55–60** | 479 / 80 | 0 of 6 | 40 + 0; −86 | 82, 0, 40 | +63 | 60 / 203 | ~10 |
| 2 | Wulstead d0–34 | 300 / 255 | 26 of 34 | 394 + 88; +342 | 610, 0, 317 | −299 | 400 / 157 (39%) | ~285 |
| 2 | Netherton d0–27 | 130 / 110 | 24 of 27 | 34 + 6; +142 | 150, 28, 0 | +7 | 200 / 47 (24%) | ~179 |
| 2 | Garton d0–21 | 200 / 170 | 18 of 21 | 2 + 155; +35 | 156, 54, 44 | −63 | 140 / 47 (34%) | ~130 |
| 2 | Higham d0–35 | 360 / 306 | 26 of 35 | 399 + 0; +368 | 338, 155, 121 (in 40) | −349 | 630 / 67 (11%) | ~573 |
| 2 | Bourton d0–21 | 160 / 136 | 19 of 21 | 7 + 0; +24 | 35, 12, 0 | −10 | 140 / 32 (23%) | ~121 |
| 2 | **Bourton reopened d35–60** | 138 / 80 | 20 of 26 | 0 + 0; +123 | 64, 0, 44 | +99 | 210 / 71 (34%) | ~144 |
| 2 | **Garton reopened d49–60** | 184 / 80 | 9 of 12 | 0 + 0; +59 | 91, 0, 38 | +45 | 120 / 42 (35%) | ~87 |

### 2b. The household side (only the days it worked the trade)

| Seed | Household | Income a day (wages) | Spending a day | Coins | Pantry (days of food) |
|---|---|---|---|---|---|
| 1 | Wulstead 13 (5 people) | 2.7 | 5.2 | 53 → 6 | 4.2 → 0.1 |
| 1 | Wulstead 14 (4) | 2.0 | 3.7 | 51 → 6 | 3.8 → 1.6 |
| 1 | Netherton 5 (4) | 2.5 | 4.6 | 48 → 8 | 4.2 → 2.3 |
| 1 | Garton 8 (6) | 3.6 | 4.9 | 55 → 38 | 4.4 → 1.1 |
| 1 | Higham 19 (2) | 1.7 | 3.8 | 40 → 12 | 3.3 → 1.9 |
| 1 | Higham 20 (1) | 1.0 | 3.4 | 61 → 13 | 3.3 → 1.4 |
| 1 | Higham 21 (5) | 4.4 | 4.8 | 30 → 11 | 3.8 → 1.7 |
| 1 | Bourton 7 (1) | 2.5 | 4.2 | 76 → 55 | 3.3 → 2.8 |
| 1 | Garton 2, reopened (6) | 0.0 | 2.5 | 40 → 12 | 2.0 → 1.0 |
| 1 | Wulstead 2, reopened (7) | 40.6 * | 19.4 | 50 → 156 | 0.6 → 1.1 |
| 2 | Wulstead 13 (6) | 2.4 | 4.9 | 49 → 19 | 4.4 → 0.9 |
| 2 | Wulstead 14 (2) | 3.8 | 4.9 | 58 → 28 | 3.3 → 2.1 |
| 2 | Netherton 5 (1) | 2.5 | 3.7 | 61 → 37 | 3.3 → 3.3 |
| 2 | Garton 8 (1) | 3.6 | 2.9 | 47 → 56 | 3.3 → 1.7 |
| 2 | Higham 19 (2) | 1.5 | 5.3 | 69 → 19 | 4.2 → 1.4 |
| 2 | Higham 20 (4) | 0.7 | 4.0 | 78 → 12 | 4.2 → 1.2 |
| 2 | Higham 21 (5) | 0.9 | 1.7 | 37 → 16 | 4.2 → 1.1 |
| 2 | Bourton 7 (6) | 2.5 | 5.8 | 56 → 12 | 4.4 → 1.1 |
| 2 | Bourton 2, reopened (4) | 3.2 | 3.8 | 35 → 24 | 2.3 → 1.6 |
| 2 | Garton 15, reopened (2) | 3.8 | 2.7 | 25 → 37 | 1.4 → 2.2 |

\* Wulstead 2's "income" is its own savings coming back. It put 479 coins into the till on reopening, the reserve is 80, and the
wage rule paid half the surplus straight back to it (section 2d).

### 2c. The profession change (`OffMapSettlement._move_jobs`, every 7 days)

A household switches when all of these hold:
- it has stayed at least `switch_stay_days` (14);
- its weekly income, as a daily rate, is under `switch_below` (4);
- the best-paying trade with workers pays at least `switch_to_at_least` (8) a worker-day and at least twice the household's rate.

The rule that triggered each exit, and its inputs:

| Seed | Household | Exit | Rule and inputs at that moment |
|---|---|---|---|
| 1 | Wulstead 13 | d20 → farmer | rate 0.00, low streak 1, stay 20 |
| 1 | Wulstead 14 | d27 → farmer | rate 0.00, low 2, stay 27 |
| 1 | Netherton 5 | d20 → farmer | rate 0.00, low 2 |
| 1 | Garton 8 | d14 → farmer | rate 0.00, low 1, first eligible week |
| 1 | Higham 19 | d14 → cook, then d56 → farmer | rate 0.00 at the first switch |
| 1 | Higham 20 | d21 → farmer | rate 1.43; then d32 moved to the village (MIGRATE-18, recorded as `migrants_out` +1) |
| 1 | Higham 21 | d49 → farmer | rate 3.00 |
| 1 | Bourton 7 | d14 → farmer | rate 0.00; the one-person household ended d15 with no hunger and no migration recorded (marriage or age; the diagnostic does not separate them) |
| 2 | Wulstead 13 | d13 → herder | rate 3.29 |
| 2 | Wulstead 14 | d27 → smith | rate 1.43 |
| 2 | Netherton 5 | d20 → farmer | rate 0.00 |
| 2 | Garton 8 | d14 → farmer | rate 0.00; one-person household ended d26 (as above) |
| 2 | Higham 19 | d14 → sawyer (d42 → weaver) | rate 0.00 |
| 2 | Higham 20 | d21 → herder | rate 0.00 |
| 2 | Higham 21 | d28 → farmer | rate 2.86 |
| 2 | Bourton 7 | d14 → farmer | rate 0.00 |
| 2 | Bourton 2, reopened | d56 → mason | rate 2.57 |

Every exit is the job-change rule (with income always far under 4 a day), at the first or second weekly look after the 14-day
stay. None was hunger-driven: no trader household was hungry when it switched. After switching, three single-person households
ended (one moved to the village, two were merged or ended without hunger), as allowed for any household.

### 2d. What it comes to

Each cause, ranked, with whether it is a real economic failure, a simulation artifact or an accounting defect:

1. **Insufficient profit: the main cause, a genuine economic failure under the current rules.**
   - In every founding period the trade's operating result (−349 to +62 over three to eight weeks) was far below the wages due
     (140–840). Even with no reserve at all, no founding trader earned its households' 10 a day.
   - The margins are thin: the trader buys from its own producers at 90% of the local price and sells locally at that price, less
     the 6% market toll.
   - Village purchases and outside payments (couriers) were often larger than its sales.
   - Turnover is not small for Wulstead and Higham (caravan sales 394–688), but it is matched or exceeded by purchases.

2. **The 85% reserve: a large share of the wage shortfall (accounting-correct; a rule effect).**
   - The founding till starts only 15% above its reserve (Wulstead 300 vs 255; operating capital 20–54 coins).
   - Traders spent 70–90% of their open days at or below the reserve, so wages were 11–39% of due. The reserve kept back most of
     the shortfall the till could have covered (about 120–670 coins per trader).
   - **Inconsistency between rules (a finding, not a defect):**
     - Buying from the village (`buy_from_village`, `trader_cash`) may draw the till down to `trader_reserve_floor` (20), well below
       the reserve.
     - Wages (`_pay_wages`) pay only above the reserve.
     - Local stocking (`_trader_collects`, `stock_trader_food`) also stops at the reserve.
     - So purchases from the caravan can spend the reserve that wages are never allowed to touch (till minimum 31–76 in several
       periods), and workers are paid last.
   - Conserved; it changes who is paid, not how many coins exist.

3. **Household expenses: a genuine economic failure following from 1–2.**
   - Spending ran 1.7–5.8 coins a day (food first, then basket goods) against income of 0–4.4.
   - Every founding trader household ran its purse and pantry down: pantries from about 4 days to 0.1–2.3.
   - None starved before switching.

4. **The profession change is the households' rational response, not a defect.**
   - The switch rule worked as designed, with inputs far below its threshold. It is the exit, not the cause.

5. **Insufficient sales on their own: secondary.**
   - Netherton, Garton and Bourton founding traders sold almost nothing to the caravan (0–41) and lived on thin local margins.
   - Wulstead and Higham sold more but bought more.

**Reopened traders** start from the new household's savings with the business type's reserve (80, not 85% of the till):
- Garton (seed 1) paid nothing in 12 days: its village purchases took the till from 173 to 20.
- Garton (seed 2) and Bourton (seed 2) paid 35% of wages; Bourton's household switched to mason on day 56.
- Wulstead (seed 1) shows a **simulation artifact** of the existing opening rule:
  - The household's whole savings above its keep go into the till, and the wage rule pays half of everything above the reserve
    straight back to that household as "wages".
  - Its 40.6 a day is its own money returning, not trading income. That inflates the income the job-change rule sees and hides
    whether the trade itself pays.
  - Conserved; it affects every business type a household opens or reopens (`_open_trade`). Recorded here for the LE wage work;
    not changed (option A).

**Accounting defects found: none.**
- Coins close exactly in every run.
- Each settlement's holders (treasury + household purses + tills) close to the coin on every day: 305 rows a seed, 0 mismatches.
- Transit and escrow were empty at the end of every day, and no audit line appeared.
- Founding and reopened tills balance against their flows (the residual is attributed to local trade).

## 3. Business reserves, operating capital, migration, closure and reopening

- **Reserves and operating capital.**
  - Founding traders: reserve 0.85 × opening till, so 15% of the till, 20–54 coins, is all the cash they can use for local stocking
    and wages.
  - Road trade allows `till − 20 − reserve / 2`.
  - Village purchases allow `till − 20`, so they draw on the reserve (see 2d.2).
  - Other businesses keep `reserve` 40 (sawyer, mason, smith, tanner, cook, weaver, healer) or 12 by default; a reopened trader 80.
- **Closure.** When the last household switched, the trader closed two weeks later:
  - seed 1: Garton, Bourton d21; Netherton d27; Wulstead d34; Higham d56;
  - seed 2: Garton, Bourton d21; Netherton d27; Wulstead d34; Higham d35.
  
  Its till went to the council and its stock to the granary, which is visible in the treasuries above. Its former households had
  already left the trade.
- **Reopening.** A household with savings took the trade up again where the traders' goods went unmet:
  - seed 1: Garton d49, Wulstead d55;
  - seed 2: Bourton d35, Garton d49.
  
  It started from its own savings: nothing of the old trader came back.
- **Migration.** One former trader household moved to the village (seed 1 Higham 20, after switching to farming). No trader
  household left while working the trade. Migration was not a cause of trader failure; it followed it in one case.

## 4. What to measure before proposing a trader compensation model (later, with LE wages and service contracts)

Nothing is proposed for implementation now.

1. **The trade's own operating result per worker-day**, separately from wages: sales by channel (caravan, road, local, food trade)
   and purchases by channel. This is the `--trader-diag` series kept over a full year and four seeds, with the residual "local
   net" split by instrumenting `_trader_collects`, `stock_trader_food` and local market sales of the trader's stock.
2. **Gross margin per unit by channel** (buy price, sell price, toll), to see whether any channel can pay a living wage at the
   settlements' price levels.
3. **Operating capital**: cash above the reserve and the floor each day, and how much of each purchase drew below the reserve
   (village purchases).
4. **Household living cost of trader households**: daily food at the settlement's price, the basket, and comforts against what a
   trader household would need to stay. This is the same measurement LE-03 budgets will make for villagers.
5. **Recirculated capital versus earned income** in any business a household opens or reopens, so the job-change rule's inputs can
   be read as earned income.
6. **Counterfactual reading only (no rule change)**: what the same series shows for the other businesses (farm, cook, smith),
   to tell whether traders are uniquely unprofitable or the settlement economy in general pays little.
7. **Village side**: the caravan's buy and sell volumes per visit, and `coin_sources`, so a trader compensation proposal can be
   checked against its effect on the village's inflow.

## How to reproduce

```sh
godot --headless --path game --script res://tests/economy_sim.gd -- --days 60 --seed 1 --every 10 --trader-diag
```

The `TRADER`, `TRHH` and `TRANSIT` lines are JSON, one per settlement, trader household and day. They read only, so the run is
otherwise identical, as the matching fingerprints above show.
