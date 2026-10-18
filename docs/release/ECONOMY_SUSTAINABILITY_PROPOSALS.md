# Economy sustainability: findings and proposals

The owner's directive of 2026-10-18 asked for three investigations:
1. Why the village exhausts its ore and stone.
2. Why the wildlife disappears.
3. How wages and merchants' cash should work.

The goal is a society that runs for years without the player: no money from nowhere and no magic
refills. **Nothing in the proposals is implemented.** Every proposal and number below is an agent
proposal, *provisional — balance review pending*, and needs the owner's approval.

Evidence comes from reading the code (cited) and from scratch runs with no player over 30 days,
seeds 1–3. Runs are deterministic; seed 1 matches `earn_sim.gd --strategy observe`. The long runs
(10–365 days) are in `LONG_RUN_SIMULATION.md`.

## 1. Resources: why the deposits run out by day 10

### Findings

**Who extracts.** 8 miners and 3 labourers run `NPCBrain._miner` (`npc_brain.gd` ~323–359). After
each load they mine again whenever any buyer has room:
- A buyer has room while it is below a fixed stock cap in `BUYS`.
- `_buyer_for` (~637) also requires the buyer to keep 15 coins after paying.
- Which ore is dug (`_wanted_ores`) depends only on the first smith's coal-to-iron ratio. It never
  looks at how much ore the village already holds.

**No real demand behind it.** The caps are fixed stock levels: smith iron 30 and coal 30; raw merchant
stone 40, iron 20 and coal 20. Every 2 days the caravan buys everything a merchant or smith holds
above half its cap, at 0.8 × value. That clears room for the next round of mining. The caravan's 600
coins a visit is in effect a bottomless export sink.

**Mineral ledger, seed 1, days 1–10:**

| | Start | Mined | Smelted | Exported raw | Used locally (building, works) | Sitting on day 10 |
|---|---|---|---|---|---|---|
| Iron ore | 16 | 300 (deposit 0 on day 10) | 166 | 80 | 0 | 70 |
| Coal | 16 | 200 (0 by day 8) | 111 | 70 | 0 | 38 |
| Stone | 24 | 240 (0 on day 10) | – | **190 (79%)** | **0** | 74 |
| Copper ore | 0 | 60 (0 on day 4) | 56 | 19 | 0 | 22 |

Seeds 2 and 3 have the same shape. Over 30 days, 224 of the 264 stone that ever existed was exported.

**The specific questions:**
- **Does extraction exceed consumption?** Yes: about 80 units a day are mined, against about 17
  iron and 11 coal smelted. Stone had no local use at all in these runs.
- **Are stocks checked before mining?** No. On day 10 the smiths held 48 iron ore while the last
  seam was being emptied.
- **Do buyers prefer buying to gathering?** Merchants and smiths never gather. Imports start only
  once a deposit is down to 10.
- **Is it permanent?** Yes: `World.mine_unit` never refills.
  - Miners leave only when every deposit is empty: all 11 became manor hands within 2.5 hours on
    day 11.
- **Is building still possible?** In 30 days, no houses or workshops were started on any seed.
  - Public works never ran: the treasury stayed below its 30-day threshold.
  - Before the corrections (`ae0e01f`), the village's stone after day 10 was the merchants' last 40
    and never came back. The approved caravan stone (INT-065) now brings up to 20 a visit once the
    deposits are worked out.
- **Miners' pay:** 9.9 coins a head a day (seed 1) and 7.7 (seed 2), at only 1.2–1.4 coins a unit.
  They mine about 7 units a day of a possible 26. Mining is limited by buyers, not by labour.

**Root causes:**
1. Fixed stock caps instead of demand, plus a caravan that buys everything above half the cap.
2. No stock check before mining, no quotas, and no ownership of the deposits.
3. Before `ae0e01f`, no outside source of stone.
4. Miners change jobs only when every deposit is at zero.

### Proposals

| | Proposal | Rules and parameters (provisional) |
|---|---|---|
| P1.1 | **Mining driven by demand** | A smith's ore target = observed smelting per day × `forge_stock_days` 4. A raw merchant's target = open building need + caravan orders + `market_stock_days` 3 × observed local sales. A miner mines an ore only while orders exceed what miners and merchants hold or carry. After `idle_order_days` 2 without orders, the miner goes to day labour or looks for work. |
| P1.2 | **The manor's mining rights** | Deposits are owned by the manor, as fields and pens are. Mining pays a royalty (`mine_royalty_share` 0.1 of the quote) into the treasury. The daily quota per ore is local need × 1.2. For stone the need includes open building sites plus a `stone_building_reserve` of 60 that may not be exported. The caravan may buy only what is left above that reserve, times `export_share` 0.5. |
| P1.3 | **The caravan as a finite regional market** | Each item has a regional price, at first its value. Per visit the caravan buys up to an export quota (iron 10, coal 10, stone 10) and sells from a finite supply (iron 12, coal 10, copper 6, stone 20). Its price is regional price × transport markup: ore 1.25, stone 1.75–2.0. Goods are ordered on one visit and delivered on the next. Any buyer may order: smiths, merchants, households building, the player. The regional price falls 5% a visit while the village exports and rises 5% while it imports. |
| P1.4 | **New seams by prospecting** | A seeded, finite list of hidden deposits per map, e.g. 2 iron, 1 coal and 1 stone of 40–80 units each. When known reserves fall below 10 days of demand, the manor pays a miner a day's wage (6) to prospect. Each day reveals the next hidden seam with chance 0.2. A found seam is the manor's, under P1.2. When the list is used up there are no more. |
| P1.5 | **A distant quarry** | An off-map quarry owned by the manor. A cart trip takes 1 day there and back and carries 20 stone, for one hired hand (6) plus a quarry fee of 0.5 a stone to the manor. Delivered cost is about 1.5–2 coins a stone: a real cost, not free stone. |

Not proposed: bigger deposits. The owner ruled that out, and it would only hide the extraction.

## 2. Wildlife: why the animals disappear

### Findings

**Starting stock.** 5 boar and 5 rabbit in each of two woods: 20 animals.

**Grazing.** It never limits them. Each wood can feed about 46 animals (open cells ÷ 15), and no
animal starved in any run.

**Breeding exists** (`fauna.gd` ~174–200). A female breeds when all of these hold:
- she is well fed;
- an adult male of her species is in the same wood;
- her `breed_days` have passed;
- the wood is under its cap.

**The hunters cause it.** On day 1 they killed 12 of the 20 before midnight, down to exactly `keep`,
2 adults per wood and species.
- **The floor ignores sex** (`Fauna.nearest_game` ~269–281). On seed 1, day 10, 3 of the 4 groups
  were one sex only, and a one-sex group can never breed again.
- Each newborn is shot as soon as it is grown.
- 30-day kills: 57, 102 and 75 by hunters on seeds 1–3, plus 1–3 by bandits.
- Hunters are then idle ("letting the game recover"), earning about 0–2 coins a day.

**Population.** It is pinned at 8 adults plus 0–10 young on every seed.

**Gaps:**
- Nothing migrates into the region.
- The player's hunting has no floor at all.
- The game has no seasons.

**Root cause:** hunting pressure against a sex-blind floor of 2, a tiny starting population (5
against room for about 46), and a closed region with no migration.

### Proposed design: a persistent wildlife population (no daily respawn)

| | Rule | Parameters (provisional) |
|---|---|---|
| P2.1 | **Carrying capacity by species:** K = open forage cells ÷ cells per animal. Births happen with probability (1 − N/K), using the world's seeded random generator. This replaces the hard cap. | `cells_per_animal` boar 40, rabbit 20 (about 17 boar and 35 rabbit per wood). The wood starts at `start_share_of_K` 0.6. |
| P2.2 | **A breeding floor by sex** that hunters, bandits and any quota respect. | `keep_males` 1 and `keep_females` 2 per wood and species. |
| P2.3 | **Migration from a finite regional pool.** The pool grows on its own up to its own limit. While a wood is under half of K, an adult may arrive each day, taken from the pool and of the sex the wood lacks; it enters at the north edge, where both woods lie. While a wood is over K, one animal a day leaves for the pool. Hunting never refills the pool, so heavy hunting drains the region too. | Pool: boar 30 and rabbit 60 at the start; growth 0.03 and 0.06 a day; limit 2 × the start. Arrival chance 0.15 (boar) and 0.3 (rabbit) a day. |
| P2.4 | **The manor's hunting rights.** A weekly quota per wood and species = (adults above the floor) × a harvest rate. A wood closes when its population is under 0.4 K and reopens at 0.5 K. NPC hunters hunt within the quota. The player may buy a tag or poach; poaching in a closed wood, if seen, is a crime and needs the owner's approval. The job board uses the quota. | `harvest_rate` boar 0.2, rabbit 0.35. `hunt_tag_fee` rabbit 1, boar 3, paid to the treasury. |
| P2.5 | **Local extinction.** A group at 0, or with only one sex, stays so until an immigrant comes. If the regional pool reaches 0, the species is gone for good. The village record notes both. | — |
| P2.6 | **Seasons.** None exist. If they are added, close hunting in the birthing season and lower K in winter. | — |

## 3. Wages and merchants' cash

### The mining job (8 coins for 6 iron ore)

The quote for iron ore is 4 × (1.2 − 0.04 × the buyer's stock, at least 0.4) × 0.6. Measured over
100 working hours (seed 1):

| Quote | Share of hours |
|---|---|
| 3 coins | 38% |
| 2 coins | 32% |
| 1 coin | 18% |
| No buyer at all | 12% (36% on seed 2) |

The average quote where a buyer exists is 2.23, so six ore are worth about **13.4 coins**; about 18
is the best case. Against that:
- **Employer's margin:** about 5.4 coins (40%) on average, 10 at best and −2 at worst. The employer
  has no tool cost ("bring your own pick").
- **Player's costs:** pick wear of 0.8–1.6 coins a shift. A shift is 90 game minutes (129 with the
  rusty pick), so about 5.3 or 3.7 coins an hour.
- **Comparisons:**
  - Day labour: 6 coins for 240 minutes, 1.5 an hour.
  - Guards and manor hands: 6 a day.
  - An NPC miner working alone: 7.7–9.9 a day.

**Verdict:** a 40% average margin is defensible for the risk of finding no buyer. But the wage is
about 80% of a miner's whole daily income, doesn't follow the market, and can leave the miner holding
ore nobody buys.

### The 15-coin cash floor (`trader_cash_floor`)

**Where it applies:** only when an NPC sells to a trade's buyer, and to caravan imports.

**Where it doesn't:**
- the player's sales;
- NPC purchases;
- wages and rewards;
- helpers' purchases.

**What it is:** a flat float with no source. It mixes household and business money in one purse
(starting purses: merchants 120, smiths 120, cooks 60).

**Effect:** buyers near 15 coins stop buying (cooks sat at 15 for days), and ore went unsold
12–36% of working hours.

**If it applied to the player too:** it would stop the player draining a buyer to 0 (B7-008). Small
buyers would often be closed to the player as well.

**What already exists:**
- Household tax exemption: 40 + 20 per member.
- Coins kept when a household splits.
- A 10-day savings test.
- Builders keep 10 coins.
- The treasury's reserve: 10 days, and 20 days for hiring.
- The caravan leaves 3 days of food.

### Proposed model: one rule for working money (NPCs and the player alike)

| | Proposal | Parameters (provisional) |
|---|---|---|
| P3.1 | **Separate household money from business money.** Each household (NPC or the player's) keeps a household reserve (`reserve_food_days` 3 × daily food cost, plus rent due within 7 days) and the wage bill it has promised (`wage_days` 2). **Free money** = coins − reserve − wage bill. Every purchase, wage, reward and import checks free money. This replaces the flat 15 and applies to NPC and player buyers alike. | `reserve_food_days` 3, `wage_days` 2 |
| P3.2 | **Quotes follow the money.** A buyer quotes only for what its free money can pay ("can take 3 of 6"); NPC sellers see the same limit. | — |
| P3.3 | **Stock targets in days of sales** (as in P1.1), so working money isn't tied up in ore that sits. | `stock_days` |
| P3.4 | **Hire wages come from the market quote.** Wage = quote for the job's quantity × (1 − the employer's share), minus wear on the employer's tools, if any. The floor is day labour's hourly rate. Work is offered only when a buyer can take the goods and the employer's free money covers the wage. At today's average quote this gives about 8–9 coins for the mine shift, 12 at the best quote and 4 in a weak market. | `hire_employer_share` 0.35 |
| P3.5 | **One code path:** `World.spendable(party)`, used by trades, quests, construction and the caravan; each use gets its INT entry. | — |

## 4. The manor's starting treasury (B7-009)

The treasury starts at 270, against the manor's own reserve rule of 460 (10 days of obligations). It
falls to about 100 by day 5 and reaches the reserve around day 12–13. Until then no day labour is
paid: neither the player's work for the manor nor NPC relief work.

**Options:**
- **(a)** A starting treasury above the reserve (e.g. 600).
- **(b)** A smaller reserve for day labour only (e.g. 3 days of obligations, 138).
- **(c)** Day labour allowed while the treasury covers 2 days of guards' and hands' wages.

**Recommendation: (b).** It keeps the 10-day reserve for hiring permanent staff, and a day's labour
is a smaller, shorter promise.

## 5. Household growth: why nothing is built, and a plan (B7-017)

Added 2026-10-18 after the long-run economy fixes (`LONG_RUN_SIMULATION.md`, "After the long-run
economy fixes"). **Not implemented.** Births, aging and natural death are listed under "Proposals
requiring decisions" in `MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md`, which also says not to add them
before the production economy is stable, and `DECISIONS.md` (2026-10-18) keeps them tracked, not
started. The numbers below are agent proposals, *provisional — balance review pending*.

### Findings (code and runs, no player, seeds 1–3, 365 days: 0 sites, 0 houses, 0 splits)

1. **Building by villagers has one trigger.** `Construction.daily` calls `Construction.crowded(h)`
   each dawn: a household that holds its house, has more living members than the house has real
   beds, and two or more adults. `_found` then lets one adult leave with the cost of a home,
   which is a house on the market, else ground, materials and `founder_build_days` of helpers'
   wages (`_home_plan`).
2. **Nothing can make a household crowded.** Every house has 5 beds (`beds_in`); 21 of the 24
   households have 4 members. The three over their beds (the tavern 6 members / 2 beds, the manor
   5 / 4, the hut 1 / 0) live in the manor's buildings and do not "hold" them, so `crowded` is
   false for them. Nobody is born, grows up, ages or arrives: 26 children and 18 elders are fixed
   for good, and in none of the runs did anyone die.
3. **The machinery works once a household is crowded.** `game/tests/households_sim.gd --seed 2
   --days 30 --crowd 3` crowds a household by hand: one adult founds a household, the ground is
   bought, a helper is hired for a day, the house is built from planks, stone and logs, and the
   family moves in, with coins and grain conserved (the run's last line: households founded 1, built
   by NPCs 1, helper wages 6, bought 105 coins).
4. **Money and materials are not the first blocker.** A founder's home costs about the land price
   (60 for a 9 x 10 plot) plus 30 planks, 20 stone and 10 logs at today's prices plus three days of
   helpers (`founder_build_days` x `helper_wage`), and the family must keep `split_keep_base` 40 +
   20 a member. Households held a median of 1,100–1,250 coins in the Build 7 runs and about 250 in
   the runs after the caravan became finite. Stone is the scarce part: after the seams are worked
   out it comes only by caravan, 20 a visit at twice its value.
5. **So the missing link is growth.** The sums the economy cannot absorb today (about 15,000 spare
   wheat, a trade surplus of idle coin, planks and stone with no use but repairs and export) are
   exactly what housing for more people would use. B7-014 to B7-017 are one problem seen four ways.

### Smallest design that closes the loop (proposal)

| Rule | Proposal |
|---|---|
| Births | At dawn, in household order, a household with two or more adult members, `birth_min_food_days` (10) of food in hand (`household_food_days`), no famine, fewer than `birth_max_children` (3) children, and `birth_interval_days` (120, staggered by household id so births are spread) since its last birth, has a child. No random numbers are drawn, so no other part of a seeded run changes. A birth is allowed only while members < beds + `birth_over_beds` (1): a household can be one over its beds, which is what makes it crowded. |
| The newborn | A new `NPC`: role "child", 0 coins, no goods, hunger 100, the household's family and home, name and sprite from `Population` by a seeded hash of the world seed and its id. It eats `child_food_factor` of an adult (already in every food reckoning). |
| Growing up | A child becomes an adult after `child_days` (180 game days, a play-test timescale, not a real age): job "", hp 30. An adult without work already looks for it (`seek_work`: manor hand, farmer, woodcutter, hunter, miner). The 26 starting children get ages staggered by id so they do not all come of age on one day. |
| Crowding and building | Unchanged (INT-060): a grown member beyond the beds founds a household and builds. |
| Natural death | Not part of the minimal loop. Without it elders never die and the village only grows until food or housing stops it (births stop at beds + 1, founding needs coin, stone and planks). Whether elders should die of age is the owner's call. |

### Implementation plan (when approved)

1. `Population.births(w)` called from `Construction.daily` before `crowded` is checked (one function,
   one place), plus `NPC.born_day`, `hh.last_birth_day` and the maturity step in the same daily pass.
   `balance.json` gets `birth_*` and `child_days` with the "provisional" note.
2. Saves: `born_day` per NPC and `last_birth_day` per household; bump `World.SAVE_VERSION` (10),
   migrate every older save (existing children get `born_day = day - child_days / 2 + id % 60`, so
   the flagged ages are staggered; households start their interval at the load day), and a
   fixture test from each older version (CLAUDE.md section 7). `World.to_dict` / `load_dict` only.
3. Interaction manifest: a new INT entry (births, growing up, crowding, food, relief, jobs), and the
   updates to INT-017 (inheritance with newborns), INT-024, INT-029, INT-047, INT-060 and INT-031.
4. Tests in `run_tests.gd`: determinism for a seed (same births on the same days); coins and goods
   unchanged by a birth; the housing gate (no birth past beds + 1); the food gate; a household born
   crowded founds a house in a long run; a v8/v9 fixture save loads with ages staggered. The harness
   (`economy_sim.gd`) already prints births, households, sites and houses; add children, adults
   and unemployed per sample.
5. A before/after 365-day run on seeds 1–3, to be reported beside the economy numbers.

### Decisions needed from the owner

1. Is "two adults in a household" enough of a couple, or does marriage (new households formed by two
   grown members) come first? That is a larger system.
2. The timescale: `child_days` and `birth_interval_days` are play-test numbers. A real calendar (a
   year of days, a generation of years) is a design choice.
3. Natural death by age, and what a household does with an empty chair (heirs, jobs, houses). The
   living-world design lists this with births.
4. Whether growth should be capped (a population ceiling) or left to food and housing.
5. A newborn's appearance (the 48 villager sheets are adults; children share sprites with them today).
