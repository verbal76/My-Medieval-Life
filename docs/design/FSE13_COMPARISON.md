# FSE-13 comparison: seasonal village farming against the current field model

Owner decision of 2026-10-21 (`docs/directives/2026-10-21_build16_owner_decision_resolution.md` section 5): seasonal
village farming is tested by comparison first and activated only with the owner's authorization. **It is not activated.**
The switch `seasonal_village_farming` stays 0 in `game/data/balance.json`.

## What was compared

- **Baseline:** Actions run 39523615798 on `1fefddb`, the current field model. A manor field ripens
  `field_grow_seasons` (one season, 2 game days) after sowing, in any season.
- **Seasonal:** Actions run 39526774144 on `df54ef1` with `set: seasonal_village_farming=1`. The fields keep the player's
  seasons (`farming.sow_seasons`, `farming.season_rate`): no sowing in winter, full growth in spring and summer, half in
  autumn, none in winter.
- **Why these two runs compare:** `df54ef1` differs from `1fefddb` only by the armoury counters and the two farming
  switches, and with both switches off the determinism gate is identical.
- **Run shape:** four seeds, 365 game days each, player inactive. The calendar is the 8-day year (OD-21): 365 days is about
  45 calendar years.

## Results at day 365

| Measure | Seed 1 (base -> seasonal) | Seed 2 | Seed 3 | Seed 4 |
|---|---|---|---|---|
| Script errors / ledgers | 0 / balanced -> 0 / balanced | same | same | same |
| Starvation deaths | 0 -> **27** | 0 -> **25** | 0 -> **22** | 0 -> **8** |
| Alive at the end | 124 -> 69 | 126 -> 96 | 106 -> 88 | 143 -> 124 |
| Births | 94 -> 56 | 96 -> 90 | 76 -> 70 | 115 -> 101 |
| Wheat harvested in the year | 43,920 -> 31,560 | 43,920 -> 31,680 | 43,920 -> 32,400 | 43,920 -> 32,220 |
| Wheat held at the end | 901 -> 4,648 | 6,063 -> 69 | 2,040 -> 5,253 | 5,847 -> 3,230 |
| Milk produced (pens) | 1,448 -> 174 | 1,452 -> 814 | 1,448 -> 176 | 1,452 -> 144 |
| Meat produced | 4,797 -> 2,283 | 4,581 -> 4,059 | 4,659 -> 2,073 | 4,368 -> 3,269 |
| Pottage cooked | 60,383 -> 39,697 | 57,341 -> 57,002 | 59,450 -> 49,187 | 65,760 -> 58,525 |
| Wool | 282 -> 44 | 279 -> 272 | 284 -> 27 | 281 -> 27 |
| Wheat seed (start, produced, imported -> end) | 68, 270, 28 -> 366 / 68, 207, 28 -> 303 | 68, 270, 22 -> 360 / 68, 229, 22 -> 319 | 68, 275, 17 -> 360 / 68, 248, 22 -> 338 | 68, 306, 26 -> 400 / 68, 264, 27 -> 359 |
| Nights without firewood | 1,466 -> 2,606 | 1,463 -> 1,527 | 1,414 -> 1,258 | 1,760 -> 2,118 |
| Houses built | 10 -> 5 | 8 -> 7 | 7 -> 5 | 10 -> 11 |
| Manor hands | 32 -> 10 | 30 -> 27 | 30 -> 20 | 36 -> 33 |

## What the comparison shows, item by item

The owner asked for these points.

- **Planting by season:** fields are not sown in winter (2 of every 8 days), as for the player.
- **Growth and harvest timing:** the average growth rate over a year is 0.625 of the current model (1 + 1 + 0.5 + 0 over
  four seasons), and a field sown in late autumn waits through winter.
- **Crop yields:** the year's grain falls by 26-28 % on every seed. The six fields still yield `field_yield` (60) a
  harvest, but fewer harvests come in.
- **Seed use:** unchanged in kind. The current field model sows without seed (FSE-12 is the seed question). The farmers'
  saved seed falls a little because there are fewer harvests to keep it from.
- **Household food:** pottage cooked falls by 1-34 %. Grain at the end is uneven: some seeds end with grain unsold while
  others run out.
- **Manor production and the pens:** the pens are fed from the farmers' grain. With less grain the animals go short, and
  milk falls by 44-90 %, wool and meat with it. This is the largest knock-on effect.
- **NPC farming decisions:** farmers wait for the sowing season ("waiting for the sowing season") and otherwise behave as
  before. No new decision logic was added: nobody stores grain ahead of winter or sows anything else.
- **Starvation and food security:** 8-27 deaths a seed against none. These deaths are not classified one by one. They
  follow from the smaller harvest and the pens' losses, not from a mechanism observed to fail, but no watched run was
  made.
- **Economic consequences:** fewer manor hands in work (10-33 against 30-36), fewer houses built (5-11 against 7-10),
  fewer births. Firewood nights rise on two seeds and fall on one.
- **Determinism:** each run is reproducible from its seed. The runs balanced their coin and item ledgers (the job fails
  otherwise) and ended with 0 script errors.

## Reading, for the owner

Seasonal farming as the player has it makes the village's food year about a quarter smaller. The current economy (six
fields, 12 farmers, pens fed from the same grain) has no slack for that, and without seasonal planning (storing grain
ahead of winter, a granary drawn down in winter, more land under the plough) the village shrinks and some households
starve.

**Recommendation:** do not activate it alone. Pair it with the land and storage work that answers a winter, such as the
family farm plots (FARM-01..05) and the shared field model (FSE-12), and compare again. **This is the owner's decision.**
