# Caravan subsidy replacement plan (SET-C; CARAVAN-TMP)

PROSPECTIVE (Expansion 18, PROS-18). The live caravan is unchanged on this branch. This plan and its harness
(`game/tests/caravan_compare.gd`) measure what replacing the 30-coin daily allowance with genuine regional trade would
do; they decide nothing. The spec's rule (s.1): "a caravan is not an automatic daily income source"; acceptance (s.11):
"No fixed 30-coin quota remains in the final demand-driven implementation."

## 1. The current caravan (FACT, `NPCBrain.caravan`, staging `b721616`)

Every `caravan_every_days` (2) at noon the caravan's purse (`World.caravan_purse`, up to `caravan_float` 1500) gains
`caravan_allowance` (30) a day, tapering as the village's coins near `caravan_ceiling_per_head` (100) a head. These are
the only coins ever created (`coin_sources`). It sells ore and coal when seams run low, stone when stone runs low,
medicines and seed; then buys the market's and producers' surplus at 0.8 x value up to `caravan_coins` (600) a visit,
whatever it is and whether or not anyone outside needs it, allocated by the sellers' need (EQ-22). It also brings the
newcomers for vacant essential posts (B8-016).

## 2. What replaces it (PLAN)

1. **Off-map settlements** (`SettlementLedger`, spec s.7 intermediate phase), saved in the settlement section, each with
   finite stocks, needs, production and a purse. Their only changes are journal lines: production, use (shortages
   recorded), explicit income (Q18-3) and matched trade.
2. **Caravan visits become trade rounds** (`RegionalMarket.plan/execute`): a region buys only what it needs, can pay for
   and can haul at a delivered price it accepts; the village buys what it needs and can pay for. Variable arrivals and
   empty trips follow (spec s.7: "support variable arrivals and empty trips").
3. **Orders as CON-01 contracts** (Build 17, `contracts.gd`): a regional buyer posts a procurement contract with reserved
   coins; village sellers deliver; lapse on failure. `RegionalMarket.execute` is the stand-in until then.
4. **The village side stays in the World's holders.** A sale moves goods from the selling villager's own inventory and
   coins into that villager's purse (as the caravan does now through `World` paths); nothing is held twice.
5. **Imports of ore, coal, stone, seed and medicine** come from regions that hold them (Eastmarch ore and coal, Highfold
   stone, Riverford seed and medicine) at their delivered price, or not at all.
6. **Newcomers decoupled** (B8-016): they arrive by road on their own schedule, not with the caravan.
7. **Remove** `caravan_allowance`, `caravan_float`, `caravan_ceiling_per_head` and the purse top-up; migrate
   `caravan_purse` into the regions' purses (the coins it holds are the region's), keeping `coin_sources` as the record
   of coins that crossed the boundary.

Migration order (each step its own tests and multi-seed comparison): (a) shadow (this branch); (b) regions saved and
ticking, caravan unchanged; (c) imports from regions; (d) exports to regions, allowance at 0; (e) allowance code removed.

## 3. Shadow harness results (measured, not judged; WDR-022)

`caravan_compare.gd -- --days 30 --seed 1` (fixture: Eastmarch mining town, Riverford market town, Highfold quarry
hamlet; closed purses totalling 2650; distances 800-1400 tiles). Integrity: 35 checks, 0 failures (the World untouched
by the shadow; every shadow transfer matched; shadow coins conserved each visit; regions' books balance; the live
currency balances).

| Over 15 visits (30 days) | Current caravan | Genuine trade (shadow) |
|---|---|---|
| Village coins in (exports) | 2986 | 1813 |
| Village coins out (imports) | 1000 | 589 |
| Net to the village | +1986 | +1224 |
| Coins created | 486 (allowance) | 0 |

Observations (seed 1, one fixture; not a general result):
- The caravan buys whatever is surplus (iron bars, logs, rings, ploughs, leather caps); the regions buy only what they
  need (wheat, bread, planks, pelts, ale). Most of the caravan's purchases have no buyer in the fixture region.
- With closed purses, the regions run down: Highfold reached its cash floor by day 17 and then could not buy
  (`highfold:funds` 91 units unmet); Eastmarch fell from 900 to 364. A closed regional currency drains into a village
  that exports more than it imports. This is the B7-014 risk the engineering plan names, measured; it bears directly on
  **Q18-3** (closed purse or an explicit, accounted regional income).
- The village's own unmet need is large (`village:no supplier` 11240 units over 15 visits) because its measured use of
  goods it makes itself (ore from its own seams, food from its own fields) counts as demand. Before integration the
  village snapshot must count local production capacity (MIN-D's deposits, farming) against demand.
- 10 days (seed 1): caravan net +1651 with 151 coins created; shadow net -100 (the village bought 481 coins of ore and coal
  on the first visit).

Reproduce: `godot --headless --path game --script res://tests/caravan_compare.gd -- --days 30 --seed 1 [--income N] [--out f.json]`.

## 4. Owner decisions this needs

Q18-3 (regional income), Q18-4 (regions), Q18-5 (barter, credit), Q18-10 (who in the village buys), and the order of
steps (a)-(e) relative to Build 17's quarry chain (MIN-B) and contracts (CON-01).
