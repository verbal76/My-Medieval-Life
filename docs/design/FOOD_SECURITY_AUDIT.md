# Food security and the goal-driven economy: audit and plan (FSE-00)

The owner's directive of 2026-10-20 (`docs/directives/2026-10-20_food_security_goal_driven_economy.md`) asks for an audit
of what exists before anything new is built, and seven deliverables (its section 19). The owner's follow-up of the same
day (`docs/directives/2026-10-20_agricultural_findings_followup.md`) orders the agricultural work, OD-21
(`docs/directives/2026-10-20_od21_time_model.md`) fixes the time model, and the owner's relief instruction (FSE-17) amends
the manor's relief. Register: FSE-00..17, TIME-01..04.

How this was established: the code was read (two read-only audits of every food, land, hunting, husbandry and goal
system, with file and line references, their defect claims checked against the code before being listed here), and the
measured figures come from the seed-2 365-day run on `5625505` (`economy_sim.gd --days 365 --seed 2 --every 30`, the
post-parity, post-relief-valuation baseline; local run, its summary kept in `docs/release/LONG_RUN_SIMULATION.md`).
Paths are relative to `game/`; `nb` is `scripts/core/npc_brain.gd`, `wd` `scripts/core/world.gd`, `fa`
`scripts/core/fauna.gd`, `fm` `scripts/core/farming.gd`, `mn` `scripts/main.gd`.

**Time units (OD-21).** A game day is 24 game hours; a calendar year is **8 game days** in four 2-day seasons. A
365-day run is about 45.6 calendar years. Figures below are given per game day and per calendar year.

## 1. Current-system audit (deliverable 1, FSE-01)

Verdicts: YES (exists and runs), PARTIAL, NO. "Runs" means a caller exists on a live path.

### Agriculture

There are two farming systems that share no code: the **village** (six manor fields `f0`-`f5`, each 11x6 cells, worked
by `NPCBrain._farmer`, `nb:1140`) and the **player's** (`Farming`, per-cell crops on land the player holds, `fm`).

| Question | Village | Player | Evidence |
|---|---|---|---|
| 1 Villagers plant crops | PARTIAL: "sowing" only flips the field's state; wheat only, only on the manor fields | YES | `nb:1157-1159`, `nb:1981-1986`; `fm:216` |
| 2 Real fields or plots | YES: 6 rectangles; one state and one crop number per field, cells drawn but not simulated | YES: per cell, on a held parcel | `wd:128-136`; `fm:61` |
| 3 Seed consumed when planted | **NO** | YES (1 a cell; no seed, no sowing) | `nb:1981`; `fm:216` |
| 4 Grow over time | YES, ripe `field_grow_days` (2) after sowing | YES, hourly progress × season rate | `wd:1359-1372`, `wd:323-329`; `fm:227-238` |
| 5 Seasons | **NO** (grows and is sown in winter) | YES (winter 0, autumn 0.5, no winter sowing) | `wd:1359`; `fm:199-210` |
| 6 Harvested by villager activity | YES (90-minute harvest after 12 h standing ripe) | YES (the player) | `nb:1961-1980`, `wd:1365` |
| 7 Food enters real inventories | YES (farmer, pens' troughs, pantry up to 10 wheat, then sale to granary and buyers) | YES | `nb:1965-1977`; `fm:257` |
| 8 Yield limited by land, labour, seed, time | PARTIAL: time only; a flat 60 wheat a field whatever its 66 cells; a second worker adds nothing | YES (3 a cell, seed, real seconds and stamina per cell) | balance `field_yield`; `field_workers_max` 2 |
| 9 Crops can fail | NO | NO (pause in winter) | no weather, soil or blight code |
| 10 Seed retained | PARTIAL: 2 seed kept a harvest (up to 12) but never sown: dead stock, sold only to the player | YES (`seeds_back` 1) | `fm:593` `save_seed`; `fm:246` |
| 11 Soil, weather, skill | NO (no Farming skill; no xp for sowing or harvest) | NO | `skills.json` |
| 12 Independent of the player | YES | — | |

Wild food runs: berry bushes (52), flowers (151) and the apple orchard (seasonal) are picked by any adult in the
evening within 30 tiles of home, up to small keeps, and regrow (`nb:333`, `wd:964`, `wd:998`).

### Food consumption (game units)

| | Per game day | Per calendar year (8 days) | Source |
|---|---|---|---|
| Adult (and elder) | 72 points (3 an hour) | 576 | balance `hunger_per_hour` |
| Child | 43.2 (`child_food_factor` 0.6) | 345.6 | `NPCBrain.food_factor` |
| Typical household at the start (100 people in 24 households: 56 adults, 18 elders, 26 children; 3.73 adult-equivalents) | 269 | 2,150 | `population.gd:7-13` |
| Village at the start | 6,451 | 51,610 | `village_day_food` |
| Village at day 365 of the seed-2 run (130 people) | 8,035 | 64,280 | the run's `day_need_points` |

Food points: wheat 20 raw, pottage 40, roast meat 60, bread 50, cheese 35, ale 10, apple 15, berries 6, carrot 12,
potato 14, egg 10, milk 12. Cooking multiplies grain: 2 wheat make 6 pottage, so a wheat is worth **120 points cooked**
against 20 raw.

Measured, seed 2, 365 game days (45.6 calendar years), from the run's goods ledger:

| | Made | Imported | Used | Exported | End stock |
|---|---|---|---|---|---|
| Wheat | 43,920 (963 a year) | 0 | 42,219 | 92 | 2,332 |
| Pottage | 64,351 | 0 | 64,371 eaten | 15 | 73 |
| Roast meat | 5,126 | 0 | 4,411 | 39 | 684 |
| Raw meat | 4,373 | 0 | 2,265 | 65 | 2,056 |
| Bread | 760 | 0 | 690 | 24 | 47 |
| Berries (both) | 5,908 | 0 | 5,846 | 0 | 62 |
| Apples | 332 | 0 | 323 | 0 | 9 |
| Eggs | 1,713 | 0 | 57 | 20 | 1,636 |
| Milk | 1,454 | 0 | 24 | 17 | 1,413 |

- Eaten: 2.92 million points, about 88 % as pottage, 9 % roast meat.
- **Imports: none** (the caravan brings no food). Exports are small.
- **Spoilage:** stored food never spoils; only unclaimed carcasses do (`wd:2696`).
- **Unexplained sources:** the starting endowment (fields ripe with 360 wheat, households' pottage and wheat, traders'
  stock, a 7-day granary) is one-off. Ongoing, **village crops come from no seed**, and **bandits' poaching and the
  clan's camp meals feed them from nothing** (`nb:2027-2041`).
- **Without imports:** yes. The village fed itself for 45 years, ending with 11.8 days of food. Its 11 starvation deaths
  came while food existed (section 2).
- **Eggs and milk pile up** (1,636 and 1,413 at the end): villagers cannot eat them, only the cook uses a few.

### Hunting

| Question | Verdict | Evidence |
|---|---|---|
| 1 Villagers hunt | YES, a certain 40-minute kill of the nearest game, no weapon, prey does not flee | `nb:1244`, act `nb:1987` |
| 2 Only professional hunters | YES (`job == "hunter"`) | `nb:788` |
| 3 A hungry non-hunter hunts | NO; nor forages when hungry | `_plan_eat` `nb:722` |
| 4 Real animals removed | YES | `fa:511`, `fa:533` |
| 5 Carcasses processed | PARTIAL: meat, hide, pelt, feather. Raw meat is not edible; only the cook roasts it, at the tavern. Households never roast at home, although the player can at a home hearth | `fa:511-530`, `nb:1119`, `furniture.gd:18` |
| 6 Goods enter the economy | YES (cook, food merchant, tanner, goods merchant, the caravan) | `nb:37-46`, `nb:3171` |
| 7 Limited by wildlife | YES: hunters leave keep + 2 of each kind a wood, never the last of a sex | `fa:556-568`, `fa:222` |
| 8 Over-hunting depletes | PARTIAL: villagers cannot; the player can empty a wood, then the refuges restock it | `refuges.gd`; scenario `hunt_out` |
| 9 Same xp for player and villager | NO: the player gets Combat xp per blow, a villager per kill; slaughter gives the player xp, the keeper none | `mn:2775`, `nb:1993` |

Measured: hunters took 942 animals (rabbit 397, bird 351, boar 127, deer 67); bandits poached 163; every wild species
lived the 45 years.

### Animal husbandry

| Question | Verdict | Evidence |
|---|---|---|
| 1 Species | cow, pig, sheep, chicken (wild: boar, rabbit, deer, wolf, fox, bear, bird) | balance `animals` |
| 2 Villagers own them | PARTIAL: a manor pen let to a farmer; nobody else | `wd:186-198`, `nb:843-854` |
| 3 Breed | YES, all year (refuges only in season) | `fa:418` |
| 4 Food and care | YES, feed only; unfed animals starve | `fa:163-204`, `nb:1186` |
| 5 Products | YES: eggs, milk, wool, meat, hide, feathers | `fm:508-535` |
| 6 Accounted | YES, except the player's kills (no `hunted_`/`slaughtered_` stat) | `economy_sim.gd:560`, `mn:2771` |
| 7 Non-farmer households | NO for villagers; the player can fence pens and buy animals | `fm:377-505` |

### Land and commerce

| Question | Verdict | Evidence |
|---|---|---|
| 1 Who owns farmland | The manor owns the fields; farmers keep the whole crop, with no rent or share | `wd:134` |
| 2 Villagers rent plots | Only for homes; manor fields cannot be leased | `property.gd:144`, `construction.gd:1118` |
| 3 Rent is a real transaction | YES: coins from the tenant to the treasury, arrears, eviction after 2 missed weeks | `property.gd:413-421` |
| 4 Market stalls | The player's (5 coins a day, real) and villager merchants' (rent-free) | `business.gd:453`, `nb:2820` |
| 5 Households sell surplus | PARTIAL: storefronts and cart runs sell poultices, berries and apples | `nb:389-434` |
| 6 More than one income | PARTIAL: one job, plus foraging, storefront and cart sales, day labour (not for farmers, cooks, hunters) | `nb:3109` |
| 7 Occupations restrict | YES: only farmers farm and keep animals, only hunters hunt | `wd:2865`, `nb:788` |
| 8 The player takes part | Partly: the player leases plots, farms, keeps pens, hunts and runs a stall; villagers cannot do most of these | |

### Goals and individual differences

- Goals that run: the household's housing goals (no home, crowded) and `saving_for_home` (`construction.gd:724-761`);
  courtship and friendship (`relations.gd`); job mobility by average pay (`nb:2736`).
- `saving_for_home` only stops courting gifts (`nb:709`). It does not protect the money from other spending.
- **There are no per-villager traits or preferences.** Every villager in a job follows the same rule; they differ
  only in coins, household, skills, place and chance. Memory is read only by dialogue.
- The OD-19 reserve (`World.necessity`, `wd:662`) is the one financial plan. It ignores eggs, milk, carrots and
  potatoes held as food.

## 2. The seed-2 starvation deaths (FSE-16)

**Method.** The baseline (seed 2, 365 days, `5625505`) was reproduced exactly with `economy_sim.gd --watch-from 200`,
which logs every game hour the households with someone under 25 hunger, each death, and each evening's relief (who
qualified at 16:00, the granary, the treasury, the sellers relief could buy from; whom the 17:00 relief helped and what
it spent). The watch restores the world's hourly caches after reading, so the run is the baseline run: the same 11
people starve, on the same days (the year log's day numbers are one higher, counted from 1). An earlier outside probe
that read those caches changed the run and was discarded. Day and hour below are the game's.

**The village around them (days 200-236).** Village food stood at 5.3-6.2 days, but it was held by farmers (their
keep: the household's days, four days of pen feed and a buffer of 10) and by vendors. Every evening 15 to 25 of the 32
households qualified for relief (under 2 days of food, counting what their coins could buy). The granary was empty
from day 208: it buys only with treasury money above its 10-day reserve, and the treasury (1,100-1,560) sat at that
reserve (1,240-1,480). Relief could buy only farmers' surplus wheat or pottage (the approved B3 rule): on **15 of the 36
evenings neither was on sale and relief helped nobody**, while bread, roast meat and other food were for sale (700-1,260
points in the evening). On the other evenings the food ran out part-way down the households **in the order of their
number**, so the high-numbered households (20, 21, 27) were repeatedly passed over at 0 days of food.

| Death (day) | Household, food and coins | Relief | Alternatives, and were they tried | Verdict |
|---|---|---|---|---|
| Ivo Ford, farmer, lived alone (215) | Pantry empty; 2 coins against meals at 3-5; he carried **318 eggs** (3,180 points, 44 days of his food) and **49 raw meat** | Qualified at 0.00-0.64 days from day 202. Helped on days 202, 204, 205 (granary). Then passed over: day 209 (granary ran out at hh21), 212 (food ran out at hh9), 214 (ran out at hh18); no sellers on 213, 215 | Eggs: villagers cannot eat them, though the player can (parity defect). Meat: households cannot roast at the hearth, though the player can (parity defect). He spent his last day "buying a meal" he could not pay for (the fixed 2-coin test) | **Broken mechanics:** relief order, inedible own food, the 2-coin tab test |
| Alice Lambert, hunter (218) | Her own 2 coins; the household's elders held **47 and 44 coins**; 6 raw meat | hh21 qualified on days 209-217; helped on 209, 211 and 217 (too late) | The family tab would have paid, but with exactly 2 coins she counted as her own payer and walked to the vendor and back until she died | **Broken mechanic:** the 2-coin tab test |
| Matilda Lambert, elder (223) | The elders' coins spent by day 222; three adults left, 0 coins, no income | Missed on 218, 219, 221, 222 (no sellers) and 220 (the food ran out at hh19); helped on 223, the day she died | Ivo carried Alice's 6 raw meat: not cookable at home | **Household poverty is a legitimate outcome; the death is a broken mechanic:** relief passed over a household at zero (order), and could not buy the food on sale (approved source rule, since amended, FSE-17) |
| Ivo Lambert, elder (234) | As above | Missed on 228, 230-234 (no sellers, or the food ran out before hh21); helped 229 and 235 | As above | As for Matilda |
| Ivo, Thomas, Edith and Gilbert Fairweather, children, and Joan Fairweather, elder (223) | A hunters' household: 0-3 coins; **13-17 raw meat** no buyer would take (the cook and merchants were full) | Qualified at 0.00-0.13 days every evening from 208; helped on 209 and 217, then on 223, the day they died; missed on 213, 215, 216, 221, 222 (no sellers), 214 and 220 (the food ran out at hh18 and hh19) | The meat could not be cooked at home (parity defect); members went "eating on the family's tab" with 2-3 coins against meals at 3-5 (the 2-coin test); children play when nobody can feed them | **Broken mechanics:** relief order, uncookable own meat, the 2-coin tab test. The unsold meat (a saturated market) is legitimate |
| Lettice and Sabina Dale, elders, no income (234, 235) | 0-1 coins, no earner | A low number, so often helped (days 200-229, ten times); on day 232 the food ran out at hh5 while hh9 stood at 0.00; no sellers on 233 and 234 | None in their reach | **Their poverty is legitimate; their deaths came from relief failing a qualifying household:** the order (day 232) and the source rule (233-234) |

**Answers to the owner's questions, in short.** Every one of the 11 qualified for relief; relief was requested by the
rule every evening; it was available on about half the evenings and was not delivered to them on most of those because
of the order of service. Alternatives existed for 9 of the 11 (their own eggs or meat, or a relative's coins) and the
simulation did not let them use them. **No death was a pure legitimate outcome.** The underlying poverty of the
Lambert and Dale households, the unsold meat and the empty granary (the treasury at its reserve) are legitimate
outcomes of the rules.

**Fixed (Build 16, `9db091b`, on staging with `722abe1`):** the family tab now decides who pays at the price asked; relief
serves the hungriest household first. Each has a regression test that fails on the old code (`reserve_test.gd`), all 27
suites pass, and the determinism gate was re-baselined with no coin or goods leaks.

**Ordered by the owner, next (FSE-17):** relief buys from every food store, and a household's food is reckoned from all
it holds. **Parity defects, next:** households roast their own meat at the hearth and eat eggs and milk, as the player
can. The seed-2 year is then rerun and compared with this baseline.

## 3. Food sustainability calculation (deliverable 2, FSE-02)

Every figure is in the game's own units. **These are the figures of the current model**, with year-round village
growth and no seed. The owner's follow-up says not to treat them as permanent: they are recalculated after the seed,
season and parity corrections (FSE-15).

**Formulas.**
- Annual requirement = daily points × 8 days. One adult: 72 × 8 = 576 points a year.
- Net edible harvest of a field = (yield − seed kept) × points a wheat when cooked = (60 − 2) × 120 = 6,960 points a
  harvest (the 2 kept seed are not sown today, so no seed is "used"; with seed consumption, FSE-11, the seed a field
  takes comes off the same way).
- Harvests a year = 8 days ÷ cycle length. Cycle = 2 days growing + 12 hours standing ripe + the work and walking
  (≈ 2 hours) ≈ 2.6 days, so about 3.1 harvests a year.
- Land requirement = annual requirement ÷ annual net edible yield of the land.

**Village fields, current model.**
- One field: 3.1 × 6,960 ≈ 21,400 points a year, enough for **about 37 adults**.
- Per cell (66 a field): ≈ 324 points a year, so an adult needs **about 1.8 field cells**.
- Six fields: ≈ 128,000 points a year against the village's 51,600-64,300: about twice what it eats. Measured
  production (963 wheat a year) is about 85 % of this ceiling, the gap being harvests that waited.
- Eaten raw, a wheat is 20 points, not 120: the same field would feed about 6 adults. Cooking is the whole difference.

**The player's plot, same crop.** 3 wheat a cell every growing cycle (1 seed in, 1 seed back), about 2.5 cycles a year
with the seasons: 7.5 wheat a cell a year, 900 points cooked: **about 0.64 cells an adult**. The difference from the
village (×2.8 a cell) comes from the land abstraction (a flat 60 a field against 3 a cell), not from labour or seed
(FSE-12 investigates it).

**Labour.** A village field needs 45 minutes of sowing and 90 of harvest a cycle: about 2 game minutes a cell. The
player's plough work is about 8 game minutes a cell (2.5 + 0.8 + 0.8 real seconds at 2 game minutes a second). Per
adult fed a year, that is about 11 and 13 game minutes. **Labour is not what limits food today; land and its yield
model are.** With 10 farmers for 6 fields (2 a field at most), losing farmers matters only when a field goes untended:
each idle field removes the food of about 37 adults.

**Seasons (what FSE-13 would change).** With the player's rules (Spring and Summer full, Autumn half, Winter none, no
winter sowing) a field has 5 growing days a year: about 2 harvests, so roughly 24-30 adults a field and 2.2-2.8 cells
an adult; the village's grain falls by about 35-40 %. Winter lasts 2 days: carrying the village through it needs about
2.5-3 days of food in store (16,000-24,000 points, 135-200 wheat cooked), which the granary target (7 days) exceeds if
it is kept full.

**Poor harvests and shortages.** Crops cannot fail today; the only "poor harvest" is a field left unworked. Spoilage
is nil. A seasonal model makes autumn and winter the lean period; the stores, the granary and the relief decide who
goes hungry then (owner review before activation, FSE-13).

## 4. Gap analysis (deliverable 3, FSE-03)

| Area | Exists | Missing |
|---|---|---|
| Agriculture | The manor's six fields, worked by farmers; the player's per-cell farming with seed and seasons | Seed at village sowing (FSE-11); one model for both (FSE-12); seasons for the village (FSE-13); crop failure; a Farming skill; villagers growing carrots, potatoes, herbs; household gardens |
| Food use | Pottage at home, the cook's meals, foraged fruit | Villagers eating eggs, milk, carrots, potatoes (the player can); households roasting their own meat at the hearth (the player can) |
| Hunting | Professional hunters, floors, refuges | Hunting by anyone (subsistence, side income); risk and failure; hunting xp parity |
| Husbandry | Manor pens let to farmers, breeding, feeding, products | Pens and livestock for any household; buying and selling animals among villagers; re-letting a pen whose keeper is gone |
| Land | House and plot leases with real rent | Leasing farmland and pen space; rent or a share of the crop from the manor fields; land supply planning (FSE-14) |
| Commerce | Storefronts, cart runs, the player's stall | Household stalls for garden and animal produce; rent parity for stalls; selling flowers to the sage |
| Relief | Granary grain, then wheat or pottage bought | Every food store (FSE-17, ordered); help by need, not by household number |
| AI behaviour | One rule per job; the housing goal; the OD-19 reserve | Individual preferences; goal-directed saving that weighs producing against buying; time and opportunity cost |

## 5. Cross-system dependency map (deliverable 4, FSE-04)

```
Land (manor fields, plots, pens) ──rent──> Treasury ──relief, granary──> Households
   │                                           ▲ tax                        │
   ▼ labour, seed, season                      │                            ▼ need (food, fuel, medicine, rent)
Crops ──wheat──> Farmers ──sale──> Granary, cook, merchants ──meals──> Households ──OD-19 reserve──> purchases
   │                 │                                            ▲
   │                 └──feed──> Pens ──eggs, milk, wool, meat──> cook, tanner
   ▼
Seed (kept, sold, caravan)          Wildlife ──hunters (floors, refuges)──> meat, hides ──> cook, tanner
Skills (PAR-01: xp from the activity) ── apply to every activity above, for the player and villagers alike
Time (OD-21): crops, breeding, ageing in calendar time; meals, wages, reserves in operational days
```

The register's interaction manifest (`docs/SYSTEM_INTERACTION_MANIFEST.md`) records each link that code changes;
the work below adds or updates its INT entries as it lands.

## 6. Implementation roadmap (deliverable 5, FSE-05)

Classes from the directive's section 18: **A** existing and working, **B** defects, **C** Build 16 foundations, **D**
the living-economy build.

**A. Existing and working:** the village field cycle and harvest; the granary; relief moving real food; hunting with
floors and refuges; pen breeding, feeding and products; real rent and eviction; storefront and cart sales; evening
foraging; the OD-19 reserve; experience from activities through the shared work functions (PAR-01).

**B. Defects, fixed in Build 16, each with a regression test** (the starvation-related ones first, after the per-death
report):
1. The family tab plans a meal at a fixed 2 coins, and a grain purchase at 3, whatever the food costs (`nb:742-760`).
2. Relief helps households in the order of their number, not their need (`nb:2380`).
3. Wheat is worth 20 points in the village's food days and famine test, 120 everywhere else (`wd:294`, caravan keep).
4. Village sowing takes no seed (FSE-11, approved).
5. A pen whose keeper is gone is never let again; its animals starve.
6. Bandits' poaching and the clan's camp meals feed them from nothing.
7. Villagers cannot sell flowers to the sage (no outlet).
8. A hunt cut short leaves its claim on a live animal for good.
9. Hunter openings count animals hunters never take (wolves, foxes, bears, birds).
10. The player's kills are missing from the wildlife ledger.
11. Parity: villagers cannot eat eggs, milk, carrots, potatoes; cannot roast at their hearth; the hearth gives villagers
    stove recipes and the player only oven ones; hunting xp per blow against per kill; the player's starvation damage
    (TIME-04). Villager merchants' stalls are rent-free while the player pays 5 coins a day.
12. Village fields ignore the seasons (FSE-13): built behind a switch, **off in the baseline**, compared and brought to
    the owner before activation.
13. Village and player yields differ (FSE-12): investigated and a shared model proposed; activation after a comparison.

**C. Build 16 foundations (small, safe, tested, baselined before and after):**
- Relief over every food store, and a household reckoning that counts all its stores (FSE-17, the owner's order).
- Households cook what they hold that can be cooked (roast meat at the hearth with a log), by the player's rule.
- Explicit time units through one conversion layer, no behaviour change (TIME-02).
- The land-planning design (FSE-14): land supply, plot and pen leases, rent to a legitimate owner; data structures only
  where safe.

**D. The living-economy build (FSE-10, with EXP-D; its number and place are the owner's, OD-LE-01):** household
gardens and leased farmland; pens and livestock for any household; side hunting and subsistence foraging; household
stalls; several incomes; individual preferences and goal-directed choices (saving for a house by producing instead of
buying, or by working more and buying); time and opportunity cost in choices; crop failure and weather; a Farming
skill; food spoilage; food imports.

## 7. Testing strategy (deliverable 6, FSE-06, FSE-08)

- **Mechanics are tested; outcomes are measured** (WDR-022). Each defect gets a deterministic regression test in the
  Godot suites. Economic outcomes (starvation, prices, food stores) are measured on the seed runs and compared with the
  recorded baselines, never asserted as pass or fail.
- **Baselines before change:** the seed-2 year on `5625505` is kept; each change that alters behaviour reruns the
  100-day scenarios and the 365-day runs (Actions) and is compared with it.
- **Conservation:** the goods and coin ledgers and the animal-count identity must balance on every run.
- **Isolation:** seasonal farming and the yield model are built behind switches and run separately before any
  activation (the owner's follow-up, sections 3-4).

The directive's 25 tests (section 17), mapped:

| # | Test | Where |
|---|---|---|
| 1 | One villager's annual food | Build 16: a test of `household_day_food` × 8 days |
| 2 | Land per villager | Build 16, after FSE-11/12/13: computed from the shared model (FSE-15) |
| 3 | Planting, growth, harvest | Build 16 (village fields), with FSE-11 |
| 4 | Seed retention and consumption | Build 16 (FSE-11) |
| 5 | Failed harvests | Living-economy build (no crop failure exists) |
| 6 | Non-farmers growing food | Living-economy build |
| 7 | Land rental and rent | Build 16 for existing leases (exists); farmland leases in the living-economy build |
| 8 | Livestock acquisition, care, breeding, production | Build 16 for the manor pens (exists, plus the re-letting defect); acquisition by households later |
| 9 | Non-hunters hunting | Living-economy build |
| 10 | Hunting pressure on wildlife | Build 16 (exists: floors, `hunt_out` scenario) |
| 11-13 | Buying versus producing by price and by goals | Living-economy build |
| 14 | Saving toward housing | Build 16 for the existing housing goal; goal-weighted spending later |
| 15-16 | Paid work over self-production; several incomes | Living-economy build |
| 17 | Households selling surplus | Build 16 (storefronts exist) |
| 18 | Stalls moving real goods and coins | Build 16 (exists; ledger) |
| 19 | Keeping food or seed back | Build 16 (seed, FSE-11; household keep) |
| 20 | Different choices under the same market | Living-economy build |
| 21 | Reserves responding to production and goals | Build 16 for production (OD-19 counts stores); goals later |
| 22 | Experience outside the main job | Build 16 (PAR-01C, exists through the shared functions) |
| 23 | No impossible simultaneous labour | Build 16: one plan at a time per person (exists; a test) |
| 24 | No goods or coins from nothing | Build 16 (ledgers; the poaching and seed defects) |
| 25 | Player and villager on the same systems | Build 16 (the parity defects above), then each new system |

## 8. Questions that need the owner (deliverable 7, FSE-07)

Only questions the directives do not answer. Each is registered (OD-22..24) and blocks only its own item.

**OD-22. Which definition the shared farming model starts from (FSE-12, and with it FSE-11's seed per sowing).** The
village and player yields differ because of the land abstraction, not labour or seed: a village field is one unit worth a
flat 60 wheat whatever its 66 cells; a player plot gives 3 wheat a cell and takes 1 seed a cell. One model must use one
of them (the follow-up says neither may simply be raised or lowered to match).
- (a) **Per-cell for both (recommended).** The manor fields become cells under the player's crop rules (seed a cell,
  season, real labour a cell for villagers at the player's rates in game minutes). At today's crop figure that is 198
  wheat a harvest a field (3.3 times today) for 66 seed, so the crop figure itself, an agent proposal from Build 13, is
  reviewed for both at once by a comparison run before anything is activated.
- (b) Per-field for both: player plots get a flat yield per plot; loses the per-cell farming the player has.
- (c) Keep both, and model the difference explicitly (manor fields as large, extensive, lower-yield land; plots as
  intensive gardens); the parity rule allows it only as a "legitimate, explicitly modeled reason".

**OD-23. What the manor's fields cost their farmers.** Farmers keep the whole crop of the manor's land and pay nothing;
the player must buy or lease land to farm. One rule for both (FSE-00 section 16): (a) farmers lease their field like any
land (rent to the treasury); (b) a share of the crop to the manor (the medieval custom; it would stock the granary);
(c) leave the manor's fields free to whoever farms them, the player included as a farmer. Recommendation: (b), because it
also gives the granary a supply that does not depend on the treasury's reserve (section 2).

**OD-24. Rent for villager merchants' stalls.** Villager merchants hold their stalls rent-free; the player pays 5 coins a
day for the same pitch. (a) villagers pay the same rent; (b) the player's pitch becomes free like theirs. Recommendation:
(a), introduced with a comparison run, since it moves coins from the food and goods merchants to the treasury every day.

Not asked, because the directives settle them: who may farm, hunt or keep animals (everyone, in the living-economy
build); individual preferences (the directive's section 10); relief's sources (the owner's FSE-17 answers); the time model
(OD-21).
