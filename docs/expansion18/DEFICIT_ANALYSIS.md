# Village deficit under genuine regional trade: decomposition (master directive section 8)

PROSPECTIVE (Expansion 18, PROS-18). Measurement only. No coin was created to change any result, and a settlement may be in hardship when the simulation produces it (WDR-022).

Source: `caravan_compare.gd -- --days 30 --seed 1 --profiles ... --local`, 15 caravan visits, set `neutral` (the active profile) and set `neutral+local`. The village trades as its parties (Q18-10). All three paragraphs sit on one seed and one region fixture.

## 0. Reconciling with the earlier −948

- The round-2 run (−948 net over 30 days) had no iron-bar production in the regions.
- In this round Eastmarch smelts bars from its own ore and coal (fixture change, `tests/fixtures/x18_regions.json`). The village's traders buy 728 coins of them.
- The neutral net is now −1654. Traders' purchases went from 1246 to 1952 (+706), almost all of it bars.
- So the decomposition below covers the earlier −948 plus the bar purchases.

## 1. Where the coins went (neutral set)

Coins out: 3215 in total. All carriage was self-collection, so there were no carriage fees.

| Item | Coins | Mostly bought by | Note |
|---|---|---|---|
| wheat | 1383 | households (1263 for all their food) | 432 coins' worth was wheat the village itself held for sale |
| iron_bar | 728 | traders (the goods merchant) | all of it was bars the village itself held for sale |
| iron_ore | 480 | the smiths | after the village's own reachable seams ran low (`local_supply`, real depletion) |
| coal | 357 | the smiths | as for iron ore |
| copper_ore | 207 | the smiths | as for iron ore |
| herbal_poultice, linen_bandage | 60 | the sage | — |

Coins in: 1561 in total. Wheat 693, meat 243, leather 186, planks 124, ale 64, axes 64, pickaxes 64, hides 39.

## 2. Causes, measured

**1. Few outlets for the village's own output.** This is the largest factor by far.
- At each visit's end the village still held 35,912 coins' worth (at price) of goods for sale that no region wanted. The largest were wheat 7,827, iron bars 4,438, poultices 3,204, copper bars 1,630, planks 1,572, axes 1,472 and swords 2,790.
- The fixture regions need only a handful of goods: Eastmarch food, leather and planks; Riverford leather, hides, tools, meat, ale and pelts; Highfold wheat, planks and pottage.
- The caravan bought much of this surplus whatever anyone needed. That is how it earned the village +1986 (including 486 coins created by its allowance).

**2. Buying abroad what the village had (local distribution).**
- 1,199 coins of purchases were goods the village's own parties held for sale (iron bars 728, wheat 432, poultices 30, copper ore 9).
- The regional model lets parties of the same place trade only through the local market, which the shadow does not run. So a household short of wheat walked to Riverford while a village trader held wheat.
- Sensitivity (`neutral+local`, the village's parties buy from each other first):
  - 5,558 coins changed hands inside the village;
  - coins out fell to 2,055 and the net to −541;
  - households short of funds rose from 8 to 57 visit-household pairs (out of 360), because local prices drew their purses down without new coins coming in.
- This is the largest correctable part. It is a modelling gap, not a currency gap: integration must run the regional market after, not instead of, the local market.

**3. Real production shortage of raw materials.**
- 1,044 coins of ore and coal were imports after the village's own reachable seams ran low. This is the depletion EQ-09 recorded, now bought from Eastmarch's finite reserves.
- A real outcome. MIN-B/MIN-D (quarrying, new finds) are the in-world answers, not currency.

**4. Unmet demand.**
- "No supplier" 31,199 units (116,698 coins at price). Most of this is the measured daily use of goods the village makes itself (food, logs, pottage), counted as demand because the shadow does not net the village's own production.
- "Funds" 424 units, worth 2,523 coins.
- "No carriage" 434 units: households with no adult, and the manor, which cannot travel while no carter can be hired (Q18-12).

**5. Willing partners.** Regions refused nothing on price ("price" 0 units). Highfold ran out of money ("funds" 45 units) once its purse reached the floor. The partners are willing but few, and they need little.

**6. Prices and affordability.**
- No unmet need was for "price".
- 8 of 360 household-visits were short of funds without the local market, and 57 of 360 with it.
- Uneven money matters only once local trade is modelled.

**7. Transport cost.**
- 0 coins: every purchase was self-collected, as no carter is offered.
- 296 trip-days of buyers' own travel (214 with the local market). This is real labour time away from the village, which the shadow records but does not yet take out of the villagers' days.

**8. Money distribution.** The region purses after 30 days were Eastmarch 1,833 (from 900), Riverford 2,451 (from 1,500) and Highfold 20 (its floor, from 250). The money went to the regions that sell food and metal. The quarry hamlet with only stone, which the village does not import, could not keep buying.

## 3. What would change the result without creating currency

These are design levers, none adopted:
- Run the local market first (cause 2): −1654 → −541 in this fixture.
- More or different regional demand (cause 1): which outsiders want what, Q18-4. Do not assume "permanent guaranteed export demand" (spec s.9).
- An explicit, accounted regional income (Q18-3), so regional purses do not drain into one direction for ever.
- Count the village's own production against its demand (cause 4), as done for ore (`local_supply`). Fields and recipes are next.

A village that still runs a deficit after these corrections is a legitimate outcome.
