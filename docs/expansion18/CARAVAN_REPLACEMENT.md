# Caravan subsidy replacement plan (SET-C; CARAVAN-TMP)

> **Status 2026-10-23: done by a different route than this plan's steps (a)-(e).** The owner decided (Q18-3, Q18-4, ECON-P1.3) that
> the off-map settlements are five simulated economies of their own and that the caravan is their traders, carrying only what they
> have and paying with their own coins; the daily allowance is gone. That is built (`OffMapSettlement`, `Regions`, DESIGN.md
> section 12, `SETTLEMENTS.md`): steps (b) to (e) landed together, with `caravan_allowance`, `caravan_float`,
> `caravan_ceiling_per_head`, `caravan_coins` and `World.caravan_purse` removed. This plan's `RegionalMarket` (any party buys from any
> other, a carter's fee) is still the analysis tool and the shadow harness below; it is not what the live caravan runs. Sections 1
> to 3 below describe the caravan as it was and the shadow measurements, kept as history.

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
2. **Caravan visits become trade rounds** (`RegionalMarket.plan/execute`). Owner Q18-10 (2026-10-21): **anyone** may
   buy from another settlement -- villagers, households, merchants, businesses, treasuries -- each from its own purse,
   and either fetches the goods itself or pays a willing carter; no free delivery, no merchant-only buying, nothing
   created. A region buys only what it needs and can pay for; so does each village party. Variable arrivals and empty
   trips follow (spec s.7: "support variable arrivals and empty trips").
3. **Orders as CON-01 contracts** (Build 17, `contracts.gd`): a buyer offers a procurement contract with reserved coins;
   the seller accepts, counters or refuses; delivery pays unit by unit; lapse on failure. `RegionalMarket.execute` is the
   stand-in until then (`to_contract_offer` gives the CON-01 shape). Carriage is a separate, paid service: CON-01 has no
   service contracts, so hiring a carter between settlements waits on the owner (Q18-12); households and off-map
   parties have no CON-01 reference yet (Q18-13).
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
hamlet; closed purses totalling 2650; distances 800-1400 tiles). The village trades as its parties (Q18-10): 18 traders,
24 households and the manor, each with its own purse, each fetching what it buys (no carter is offered: Q18-12). Its own
reachable seams count against its ore demand. Integrity: 50 checks, 0 failures (the World untouched by the shadow;
every shadow transfer matched; shadow coins conserved each visit; nothing delivered free; regions' books balance; the
live currency balances).

| Over 15 visits (30 days) | Current caravan | Genuine trade (shadow) |
|---|---|---|
| Village coins in (exports) | 2986 | 1561 |
| Village coins out (imports, carriage included) | 1000 | 2509 (traders 1246, households 1263) |
| Net to the village | +1986 | -948 |
| Coins created | 486 (allowance) | 0 |

Observations (seed 1, one fixture; not a general result):
- The caravan buys whatever is surplus (iron bars, logs, rings, ploughs, leather caps); the regions buy only what they
  need (wheat, bread, planks, pelts, ale). Most of the caravan's purchases have no buyer in the fixture region.
- Once households buy food with their own purses (Q18-10), the village becomes a net importer in this fixture: coins
  flow out to Riverford's grain (Riverford's purse rose from 1500 to 2451). With the caravan the village gains 1986 net;
  with genuine trade it loses 948. Under WDR-022 both are legitimate; which is plausible depends on the regions' needs
  and the village's food balance, not on a quota.
- Highfold (250 coins) reached its cash floor by day 23 and then could not buy (`highfold:funds` 45 units). A closed
  regional purse can still drain; this bears on **Q18-3** (closed purse or an explicit, accounted regional income).
- `village:no carriage` 576 units: households with no adult cannot fetch goods, and no carter can be hired (Q18-12).
- `village:no supplier` stays large: measured use of goods the village makes itself (food from its fields) counts as
  demand; local production capacity beyond seams (farming) is not yet counted against demand.
- History: the first version (traders' purses only, seller-hauled) gave +1224 net; adding own seams cut ore imports on
  the 10-day run from 517 to 168 coins.

Reproduce: `godot --headless --path game --script res://tests/caravan_compare.gd -- --days 30 --seed 1 [--income N] [--out f.json]`.

## 4. Owner decisions this needs

Q18-3 (regional income), Q18-4 (regions), Q18-5 (barter, credit), Q18-12 (hiring a carter between settlements), Q18-13
(CON-01 references for households and off-map parties), and the order of
steps (a)-(e) relative to Build 17's quarry chain (MIN-B) and contracts (CON-01).
