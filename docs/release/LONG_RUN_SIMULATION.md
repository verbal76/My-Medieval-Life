# Long-run economy simulation (Build 7 rules)

This report describes what the village does on its own over 10, 30, 100 and 365 game days, with
no player activity. It is diagnostics only: no game parameter was changed, and nothing was tuned.
Every number below is current behaviour on `staging/my-medieval-life` at `79ffeb7`, plus the
behaviour-neutral ledger counters listed at the end.

## How it was run

`game/tests/economy_sim.gd` builds `World.new()`, calls `setup(VillageMap.load_default(), seed)`,
and steps `World.update(0.5)` 1440 times per game day. That is one game minute per step, the step
used by `households_sim.gd`, `econ_report.gd` and `earn_sim.gd`.
- No larger step was needed. 365 days ran in 9 to 11.5 minutes.
- The step is also the abstract tier's tick: a distant NPC updates once every 0.5 s. A larger step
  would change which rules apply.

The player is left inert where it starts, as in `households_sim`. Its hunger is set to 100 after
every step. Nothing else about the player is touched. In every run it was never hurt (minimum hp
100) and never died.

```sh
godot --headless --path game --script res://tests/economy_sim.gd -- --days 10|30|100|365 --seed N [--every D] [--out file.json]
```

- The tool prints one line per sample: every D days (default 1), plus day 0 and the last day.
- It then prints a full final report, the flow accounts and a state fingerprint.
- `--out` writes every sample as JSON (`"format": "economy-sim/1"`).
- The exit code is 1 if the currency or any item fails to balance.

Runs: seeds 1 and 2, `--every 1`, sequentially on a 4-core cloud container.

| Days | Seed 1 runtime | Seed 2 runtime |
|---|---|---|
| 10 | 24 s | 32 s |
| 30 | 51 s | 74 s |
| 100 | 167 s | 177 s |
| 365 | 689 s (1.9 s/day) | 530 s (1.5 s/day) |

**Behaviour neutrality of the counters.** The state fingerprint (an md5 of every NPC's id, alive
flag, coins, position, hunger, job and inventory, plus animals, deposits, pantries, the treasury,
coin_sources and the RNG state) was compared before and after the counters were added. After 10
days it was identical: seed 1 `436c70a5…`, seed 2 `fbec1f64…`. Adding `held_by_job` to the
harness left the seed 1 100-day fingerprint unchanged (`dd893e3b…`). The existing suites still
pass: `run_tests.gd` 588 checks, 0 failures; `start_test.gd` 219 steps, 0 failures;
`play_test.gd` 37 steps, 0 failures. `tools/check_interactions.py` reports 0 problems.

## Results by duration

Column notation:
- **Household cash:** min / median / max, with the total in brackets.
- **Traders unable to buy:** trading NPCs whose coins minus their cheapest buy price is below
  `trader_cash_floor` (15), so a sale to them is refused, out of all trading NPCs, with the
  number at 0 coins in brackets.
- **Ore left:** iron / coal / copper / stone still in the deposits.
- **Ore held:** the same four items, held anywhere in the village.

### 10 days

| | Seed 1 | Seed 2 |
|---|---|---|
| Alive / deaths / births | 100/100, 0, 0 | 100/100, 0, 0 |
| Food (days of need), mean hunger | 6.3, 65.5 | 6.2, 65.9 |
| Missed meals, hours at zero hunger | 0, 0 | 0, 0 |
| Unemployed adults, job changes | 0 / 56, 0 | 0 / 56, 0 |
| Household cash | 39 / 174 / 334 (4473) | 42 / 158 / 324 (4067) |
| Treasury, merchants' coins | 335, 845 | 282, 792 |
| Traders unable to buy | 1 / 17 (0) | 3 / 17 (0) |
| Ore left | 0 / 0 / 0 / 0 | 116 / 0 / 0 / 0 |
| Ore held | 70 / 38 / 22 / 74 | 72 / 67 / 26 / 74 |
| Grown trees, logs, planks | 224, 173, 70 | 228, 170, 53 |
| Wild, penned animals | 12, 33 | 22, 33 |
| Hunted | 30 | 20 |
| Sites finished / started, houses, households | 0/0, 0, 24 | 0/0, 0, 24 |
| Caravan coins in / out | 2106 / 120 | 1658 / 96 |
| Currency start → end, leak | 2882 → 4868, 0 | 2858 → 4420, 0 |
| Item, deposit and animal leaks | none | none |

### 30 days

| | Seed 1 | Seed 2 |
|---|---|---|
| Alive / deaths / births | 100/100, 0, 0 | 100/100, 0, 0 |
| Food (days), mean hunger | 8.3, 67.0 | 8.2, 69.1 |
| Missed meals, hours at zero hunger | 0, 0 | 15, 0 |
| Unemployed, job changes | 0, 11 | 0, 11 |
| Household cash | 35 / 232 / 439 (5888) | 8 / 227 / 471 (5508) |
| Treasury, merchants' coins | 1152, 932 | 1139, 773 |
| Traders unable to buy | 3 / 17 (1) | 3 / 17 (0) |
| Ore left | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| Ore held | 30 / 27 / 22 / 40 | 32 / 30 / 26 / 40 |
| Imported iron / coal / copper ore | 214 / 156 / 111 | 164 / 136 / 108 |
| Grown trees, logs, planks | 208, 166, 61 | 214, 174, 51 |
| Wild, penned | 14, 32 | 24, 32 |
| Hunted | 57 | 102 |
| Sites, houses, households | 0/0, 0, 24 | 0/0, 0, 24 |
| Caravan coins in / out | 5875 / 1657 | 5248 / 1388 |
| Currency, leak | 2882 → 7100, 0 | 2858 → 6718, 0 |
| Item leaks | none | none |

### 100 days

| | Seed 1 | Seed 2 |
|---|---|---|
| Alive / deaths / births | 100/100, 0, 0 | 100/100, 0, 0 |
| Food (days), mean hunger | 17.1, 69.3 | 16.9, 68.8 |
| Missed meals, hours at zero hunger | 61, 0 | 107, 0 |
| Unemployed, job changes | 0, 11 | 0, 15 |
| Household cash | 19 / 313 / 710 (8940) | 40 / 341 / 969 (8841) |
| Treasury, merchants' coins | 3535, 1375 | 3327, 1083 |
| Traders unable to buy | 5 / 17 (4) | 2 / 16 (0) |
| Ore held | 30 / 27 / 22 / 12 | 32 / 29 / 24 / 12 |
| Imported iron / coal / copper | 1054 / 716 / 391 | 1004 / 696 / 388 |
| Grown trees, logs, planks | 214, 174, 36 | 211, 178, 43 |
| Wild, penned | 12, 33 | 8, 32 |
| Hunted | 112 | 354 |
| Tools broken | 42 axes | 39 axes |
| Sites, houses, households | 0/0, 0, 24 | 0/0, 0, 24 |
| Caravan coins in / out | 17190 / 7537 | 16649 / 7268 |
| Currency, leak | 2882 → 12535, 0 | 2858 → 12239, 0 |
| Item leaks | none | none |

### 365 days

| | Seed 1 | Seed 2 |
|---|---|---|
| Alive / deaths / births | 100/100, 0, 0 | 100/100, 0, 0 |
| Food (days), mean hunger | 48.6, 65.8 | 49.1, 67.5 |
| Missed meals, hours at zero hunger | 321, 0 | 496, 0 |
| Relief grain given, nights without firewood | 96, 16 | 141, 58 |
| Unemployed, job changes | 0, 13 | 0, 20 |
| Household cash | 14 / 842 / 2334 (24388) | 85 / 852 / 2497 (23129) |
| Treasury, merchants' coins | 4071, 3635 | 4327, 2919 |
| Traders unable to buy | 5 / 16 (3) | 3 / 15 (1) |
| Ore held | 31 / 20 / 16 / 12 | 20 / 20 / 18 / 12 |
| Imported iron / coal / copper | 3251 / 2151 / 1073 | 4172 / 2808 / 1444 |
| Grown trees, logs, planks | 208, 167, 39 | 208, 176, 39 |
| Wild (boar, rabbit) | 8 (4 adults, 4 adults, no young) | 8 (4, 4, no young) |
| Penned (cow, pig, sheep, chicken) | 34 (6, 8, 8, 12) | 32 (5, 8, 7, 12) |
| Hunted, slaughtered, poached by bandits | 112, 1439, 220 | 354, 1436, 15 |
| Tools broken | 155 axes, 4 hammers | 154 axes, 4 hammers |
| Sites, houses, households | 0/0, 0, 24 | 0/0, 0, 24 |
| Caravan coins in / out | 48313 / 22676 | 54113 / 29444 |
| Goods exported (units) | 13524 | 14034 |
| Currency, leak | 2882 → 28519, 0 | 2858 → 27527, 0 |
| Item, deposit and animal leaks | none | none |

## Trends

| Day | 0 | 10 | 30 | 100 | 200 | 300 | 365 |
|---|---|---|---|---|---|---|---|
| Currency, seed 1 | 2882 | 4868 | 7100 | 12535 | 18832 | 24833 | 28519 |
| Treasury, seed 1 | 270 | 335 | 1152 | 3535 | 3378 | 4013 | 4071 |
| Median household cash, seed 1 | 73 | 174 | 232 | 313 | 561 | 645 | 842 |
| Food (days of need), seed 1 | 3.0 | 6.3 | 8.3 | 17.1 | 28.7 | 40.7 | 48.6 |
| Currency, seed 2 | 2858 | 4420 | 6718 | 12239 | 18820 | 24174 | 27527 |
| Treasury, seed 2 | 270 | 282 | 1139 | 3327 | 3972 | 4355 | 4327 |

- **Currency grows without limit.** It grows about 70 coins a day (seed 1) to 68 (seed 2), all of
  it the caravan's net inflow; nothing removes coins from the village except caravan imports. It
  is ten times the start after a year. The money ends up with the carpenters (2333), the food
  merchants (1879), the raw-goods merchants (1754) and the richest households (max 2334 to 2497).
- **The treasury rises, then plateaus.** It falls to about 100 on day 5, rises to about 3500 by
  day 100, then holds at 3300 to 4900. Public works start spending the excess on day 64 (seed 1)
  and day 71 (seed 2).
- **Food rises steadily.** Stock grows from 3 to about 49 days of need. Almost all of it is raw
  wheat held by farmers: 4182 wheat on day 100 and 14495 on day 365 (seed 1). Household pantries
  stay at about 3600 points.
- **Population is completely static.** In 365 days no villager died or was born and no household
  split. No bandit was killed, and the bandits' 55 coins never moved.
- **Employment stays full, but the mix changes.** No adult is ever unemployed. All 11 miners and
  laborers became manor hands on day 11 (seed 1) or day 14 (seed 2).
  - Seed 1, day 155: a hunter and a tanner became farmers.
  - Seed 2: one tanner left on day 73 and the other on day 165. Hunters fell from 4 to 1.

## Failures and bottlenecks observed

| # | What | When | Notes |
|---|---|---|---|
| 1 | **Every deposit is exhausted** | Copper day 4–5, coal day 8–9, stone day 10, iron day 10 (seed 1) / 13 (seed 2) | 800 units in 14 seams; the first coal seam ran out on day 1. From then on all ore and coal comes from the caravan: 3251 iron ore (seed 1) to 4172 (seed 2) a year. Iron imports start on day 12 (seed 1) and day 18 (seed 2). Stone is never imported, and only 12 are left in the village after day 100 |
| 2 | **Mining jobs disappear** | Day 11 / 14 | All 8 miners and 3 laborers switch to manor hand, paid from the treasury. Pickaxes never break after that |
| 3 | **Unbounded currency inflation** | Whole run | See Trends. There is no coin sink apart from caravan imports (about 47% of coins in, seed 1). Prices are fixed by item value, so the extra coins pile up instead of driving prices |
| 4 | **Business insolvency** | Tanner at 0 from day 24 (s1) / 31 (s2); goods merchants at 0–2 coins from day 32 (s1) and by day 365 (s2) | The goods merchants and tanners lose coins while the other traders gain. Both tanners in seed 2, and one in seed 1, gave up the trade; on day 365 seed 2 has no tanner. A smith in seed 1 and a tavernkeeper in both seeds are below the buying floor on day 365 |
| 5 | **Missed meals while food piles up** | First on day 35 (s1), day 14 (s2); 321 and 496 by day 365 | Nearly all are `missed_meal_no_food_for_sale` (318 of 321 in seed 1), at a time when farmers hold over 14000 wheat. The bottleneck is distribution or cooking, not production. No villager ever reached zero hunger, and the lowest hunger seen was about 30 |
| 6 | **Grain hoarded by farmers** | Grows about 40 wheat a day | 14495 wheat in farmers' hands by day 365 (seed 1). The granary stays at its starting 377 all year; procurement bought 95 coins' worth in seed 1 |
| 7 | **Construction never starts** | Whole run | 0 sites started and 0 houses built, even with household cash up to 2497. Households split only when crowded, and with no births nothing is ever crowded (`households_sim` crowds households by hand to test it) |
| 8 | **Wild animals stop breeding** | Rabbits from about day 10 (s1) / 100 (s2); boar from about day 250 (s1) / 79 (s2) | Each kind falls to 4 adults with no young and no further births. That matches 2 woods × `keep` 2. Hunting then stops (last kill on day 79, seed 1). Not checked: whether the survivors are all one sex or not fed well enough. Wildlife does not go extinct, but it is frozen |
| 9 | **Firewood shortages** | First night day 53 (s1), day 9 (s2); 16 and 58 household-nights a year | Households burn a log every night (8744 logs a year). Axes break steadily (155 a year), and grown trees settle at about 208 of 305 |
| 10 | **Planks run low** | From day 100 | Planks held fall from 70 (day 10) to 36–43 by day 100 and stay there. They are drained by repairs, public works and exports (976 a year) |
| 11 | **Relief despite plenty** | From day 24 (s2) / 117 (s1) | Relief grain still goes to the poorest households: 96 and 141 wheat a year. The minimum household cash is 14 (seed 1), against a median of 842 |

## Flow accounting

The tool checks four identities at every sample.

| Identity | Formula |
|---|---|
| Currency | end total = start total + caravan coins in − caravan coins out |
| Items | end held = start held + produced + imported − consumed − exported |
| Deposits | start amount − end amount = mined |
| Animals | end = start + born − hunted − slaughtered − poached − starved |

**Currency holders** are counted independently of `World.total_coins`: villagers, bandits, dead
NPCs, the player, the treasury and coins in loot bags. Households hold no coins of their own; a
household's purse is its members' coins. Building contracts hold no coins either: wages are paid
on hire. The independent sum always equalled `total_coins`. The change in `coin_sources` always
equalled coins in minus coins out.

**Items are held** by:
- NPCs; trading NPCs and the tavern tables are counted as markets
- household pantries
- the granary
- pen troughs
- materials delivered to building sites and loads carried by hired helpers
- the player's pack and chest
- loot bags

For each item, the identity's four flows are:
- **Entering from outside:** the caravan's imports (`imported_`).
- **Leaving:** exports (`exported_`), and the coins paid for imports, which leave with the caravan.
- **Produced:** recipes, home cooking, harvest and kills (`made_`), mining (`mined_`) and felling
  (`felled_`).
- **Consumed:**
  - eaten (`eaten_`)
  - used in recipes (`used_`)
  - building (`used_building_`)
  - public works (`used_works_`)
  - repairs (`used_repairs_`)
  - trough feed (`feed_eaten_`)
  - firewood (`burned_`)
  - broken tools (`broke_`)
  - game poached and eaten at the bandit camp (`poached_lost_`)

**Result: no leak in any of the 8 runs.** The currency difference is 0. No item, deposit or animal
kind has a residual at any sample. Before the counters were added, the same identities showed
large residuals in every material: mining, felling, hides, repairs and the caravan's gross coins
were simply uncounted.

Not covered: what the player does through `main.gd` (mining, felling, kills) is not counted,
because the player is inert here.

## Counters added (behaviour-neutral)

All of them are `World.stat` calls next to existing code; none changes a value the game reads.

| File:line | Counter |
|---|---|
| `game/scripts/core/npc_brain.gd:936` | `mined_<ore>` |
| `game/scripts/core/npc_brain.gd:938` | `broke_pickaxe` |
| `game/scripts/core/npc_brain.gd:948-949` | `trees_felled`, `felled_log` |
| `game/scripts/core/npc_brain.gd:951` | `broke_axe` |
| `game/scripts/core/npc_brain.gd:965-966` | `broke_hammer` (the existing `wear` call's result, previously ignored) |
| `game/scripts/core/npc_brain.gd:999` | `hunted_<species>` |
| `game/scripts/core/npc_brain.gd:1026` | `slaughtered_<species>` |
| `game/scripts/core/npc_brain.gd:1037-1040` | `poached_<species>`, `poached_lost_<item>` (the existing `kill` result, previously discarded) |
| `game/scripts/core/npc_brain.gd:1176` | `used_repairs_<item>` |
| `game/scripts/core/npc_brain.gd:1742` | `caravan_coins_in` |
| `game/scripts/core/npc_brain.gd:1771` | `caravan_coins_out` |
| `game/scripts/core/world.gd:281` | `burned_log` |
| `game/scripts/core/fauna.gd:138` | `starved_<species>` |
| `game/scripts/core/fauna.gd:190` | `born_<species>` |
| `game/scripts/core/fauna.gd:244` | `made_hide` |


## With the manor's job board (staging `f836aca`, 2026-10-18)

The same harness, rerun from a worktree pinned at `f836aca`. That commit adds the Build 7 economy corrections, the quest-reward reserves, the caravan stone and the manor's job board (INT-066). Seeds 1 and 2; the raw outputs were in `/home/user/mml-sim/out/longrun/` (not committed).

| | Seed 1, 365 days | Seed 2, 365 days |
|---|---|---|
| Alive, starvation deaths | 100/100, 0 | 100/100, 0 |
| Food stock (days of need), mean hunger | 49.6, 68 | 51.2, 68 |
| Missed meals: no food for sale / no money | 451 / 14 | 299 / 45 |
| Currency start → end, leak | 2,882 → 36,214, 0 | 2,858 → 34,336, 0 |
| Caravan coins in / out (net) | 62,995 / 29,678 (+33,317) | 60,985 / 29,522 (+31,463) |
| Household cash min / median / max | 72 / 1,111 / 3,359 | 107 / 1,255 / 3,382 |
| Treasury; tax, wages, repairs in the year | 2,871; 44,467, 28,500, 13,337 | 3,461; 51,769, 34,766, 13,709 |
| Traders at 0 coins | tanners 2 of 2, tavernkeeper 1 of 2; goods merchants 2 coins between them | goods merchants 2 of 2, tavernkeeper 1 of 2 |
| Manor jobs done (haul, mend, quarry); wages | 5,328 (2,002, 3,326, 0); 3,970 | 5,518 (2,099, 3,419, 0); 4,776 |
| Manor hands at the end | 4 | 10 |
| Seams left | 1 stone | none |
| Imported iron ore / coal / copper ore | 4,214 / 2,824 / 1,450 | 4,193 / 2,810 / 1,440 |
| Exported logs, planks, wheat | 3,204, 2,957, 3,618 | 3,411, 2,222, 3,620 |
| Wild boar, rabbit (adults at the end); hunted | 16, 4; 182 | 16, 4; 300 |
| Building sites, houses, households split | 0, 0, 0 | 0, 0, 0 |

The 100-day runs (seed 1 / seed 2):
- All 100 alive; currency 13,317 and 13,387; no leaks.
- Manor jobs 1,131 and 1,261.

**What the year shows**
- **The village survives and conserves.** Every coin, item, deposit and animal balances on both seeds, and nobody starves.
- **The job board works without inventing demand.** Villagers carry and use the manor's repair materials every day: about 15 jobs a day, paid from the treasury. The manor buys up to its 40-load stock, so that much always waits at a seller's for carriers. No quarry job ever ran: the stone seams are worked out by about day 10, before the reeve looks for stone.
- **Unbounded money from the caravan.** The caravan buys every surplus every 2 days, so currency grows about twelvefold in a year. Prices are fixed values, so this shows as idle cash, not inflation. This is the root of proposal P1.3 (a finite regional market).
- **Food sits where it is not for sale.** About 300,000 food points are held by villagers, mostly farmers' and cooks' stock, while meals are missed 300–450 times for "no food for sale".
- **Two trades go broke.** The tanners and the goods merchants buy more than they sell back and end at 0 coins.
- **Nothing is ever built.** No household grows without births, so none splits and nobody builds (tracked future work F-2).
- **The forge runs on imports.** Every iron, copper and coal unit after day 10 is imported.
- **Wildlife holds at the hunting floor.** Boar settle at 16 wild adults; rabbits at 4 adults with almost no births on seed 2.

These are logged as B7-014 to B7-017 in `BUILD_7_ISSUES.md`. All need the owner's choice among the proposals in `ECONOMY_SUSTAINABILITY_PROPOSALS.md`, so nothing was changed.


## Build 14 candidate (staging `386498b`, 2026-10-19)

The first long runs since Build 7 rules, on the code that will become Build 14. Diagnostics only: no game numbers were
changed to obtain these results.

### How it was run

`game/tests/economy_sim.gd -- --days 100 --seed N --every 10` for seeds 1 and 2:
- no player activity;
- one game minute per step;
- an 8-day year, so 100 days is 12.5 game years.

**Starting conditions:** the fixed village (generator v6), with:
- 100 people, 24 households;
- 2,927 coins (seed 1) and 2,903 (seed 2);
- treasury 270;
- deposits: 300 iron ore, 200 coal, 240 stone, 60 copper ore, 8 gold ore;
- 54 wild animals and 13 penned.

The runs are reproducible: the same seed gives the same fingerprint.

**Ledger fix first.** The first runs reported 15 "item leaks". None was a duplication; the simulation's ledger did not
count production paths added since Build 7 (foraging, apple picking, pen products, seed kept back, handcarts set
down, wildlife eating berries). Those are now recorded (commit `a5cf3e8`). Both runs now
balance money, every item and every animal kind exactly (leak 0).

### Results

| Run | Day | Alive | Unemployed | Coins | Household cash min/median/max | Treasury | Wild animals | Food (days) | Caravans |
|---|---|---|---|---|---|---|---|---|---|
| seed 1 | 0 | 100 | 0 | 2927 | 38/73/420 | 270 | 54 | 3.0 | 0 |
| seed 1 | 20 | 103 | 0 | 4589 | 8/169/261 | 239 | 29 | 5.7 | 10 |
| seed 1 | 40 | 104 | 3 | 4752 | 2/180/240 | 200 | 24 | 5.6 | 20 |
| seed 1 | 60 | 101 | 12 | 4912 | 1/166/282 | 182 | 18 | 7.1 | 30 |
| seed 1 | 80 | 104 | 16 | 5067 | 0/172/309 | 191 | 16 | 8.5 | 40 |
| seed 1 | 100 | 104 | 24 | 5217 | 19/168/437 | 360 | 6 | 8.6 | 50 |
| seed 2 | 0 | 100 | 0 | 2903 | 28/64/420 | 270 | 54 | 3.0 | 0 |
| seed 2 | 20 | 104 | 0 | 4568 | 27/166/278 | 185 | 26 | 5.6 | 10 |
| seed 2 | 40 | 106 | 2 | 4737 | 1/172/227 | 182 | 20 | 5.7 | 20 |
| seed 2 | 60 | 107 | 6 | 4899 | 3/171/238 | 190 | 13 | 7.0 | 30 |
| seed 2 | 80 | 105 | 9 | 5059 | 2/140/296 | 240 | 5 | 8.5 | 40 |
| seed 2 | 100 | 102 | 13 | 5210 | 2/134/417 | 165 | 2 | 9.0 | 50 |

**What each run shows**

- **Currency:** grows from 2,927 to 5,217 in 100 days (seed 1), and 2,903 to 5,210 (seed 2), about 1.8 times.
  - The caravan brings 4,972 coins in and takes 2,682 out (seed 1).
  - Under Build 7 rules the currency grew about tenfold in a year; the caravan's finite purse holds it far lower.
- **People:**
  - No starvation.
  - Deaths are all of old age (12 and 17).
  - The population holds at 101–107.
- **Work:** unemployment rises from 0 to 24 (seed 1) and 13 (seed 2) of about 76 adults. These are young adults who
  come of age with no trade to take up; building never starts (0 sites, 0 houses).
- **Food:** stocks rise from 3 to about 9 days of need.
  - Missed meals: 738 in seed 1 (553 of them laborers') and 234 in seed 2.
  - Missed meals come from money, not supply: laborers cannot always afford a meal.
- **Household wealth:** the median holds at about 135–180. The poorest household dips to 0–3 coins at times, and
  recovers.
- **Resources:** local iron ore, coal and copper ore run out by day 10, and gold by day 10.
  - After that the caravan imports ore: 401 iron ore, 235 coal and 109 copper ore over 100 days in seed 1.
  - With that, the forge keeps producing (330 iron bars).
  - In the first ten days the village also exports 57 iron bars.
  - Stone lasts to about day 40–100.
- **Trade:** the caravan visits 50 times and buys 941 goods (bars, tools, planks, food, feathers).
- **Wildlife:** collapses.
  - Wild animals fall from 54 to 6 (seed 1) and 2 (seed 2).
  - In seed 1, rabbits are gone by day 40, boar and foxes by day 70, deer and wolves by day 90; 2 bears and a few birds remain.
  - The village hunter took only 6 deer, 4 boar and 9 rabbits. The rest died to predators and old age, faster than they bred.
  - This is the B14-08 food chain without the protected breeding refuges the owner has since approved (WR-01).

### 365 days (seed 1, the same code before the ledger fix; money and population figures unaffected)

- Population falls from 100 to 69: 68 deaths, almost all of old age over about 45 game years.
- Wildlife reaches 0 by day 320.
- No house is built.
- The currency reaches 6,522.

Recorded as B14R-12 for investigation; the owner's companion to the World Design Rules asks for its causes to be
found, not assumed.

### The two economy changes made without an owner decision (B14R-02)

Seed 1, 100 days. "Off" means:
- **Manor reserve off:** `manor_job_reserve_days` = 10, the long reserve.
- **Caravan limit off:** an unlimited caravan purse, as before B7-014.

| Configuration | Coins day 100 | Caravan coins in / out | Treasury | Manor wages | Manor jobs | Unemployed | Household cash min/median/max | Missed meals | Deaths | Goods exported |
|---|---|---|---|---|---|---|---|---|---|---|
| Both on (current) | 5,217 | 4,972 / 2,682 | 360 | 4,896 | 1,507 | 24 | 19/168/437 | 738 | 12 | 941 |
| Reserve on, limit off | 11,639 | 12,515 / 3,803 | 1,900 | 2,460 | 2,134 | 10 | 17/328/618 | 77 | 14 | 4,221 |
| Limit on, reserve off | 5,210 | 7,061 / 4,778 | 415 | 1,940 | 662 | 24 | 0/175/306 | 910 | 15 | 953 |
| Both off | 12,051 | 14,645 / 5,521 | 2,236 | 1,988 | 1,913 | 6 | 14/276/616 | 121 | 16 | 4,378 |

**Limitations:**
- One seed, 100 days, no player.
- The differences in deaths (12–16) are within the natural spread of old age.

Two moderate caravan settings (limit on, seed 1, 100 days) were also run:

| Configuration | Coins day 100 | Caravan coins in / out | Treasury | Manor wages | Manor jobs | Unemployed | Household cash min/median/max | Missed meals | Deaths | Goods exported |
|---|---|---|---|---|---|---|---|---|---|---|
| Ceiling 200 coins a head | 5,543 | 5,344 / 2,728 | 478 | 4,566 | 1,438 | 23 | 2/167/387 | 1,048 | 14 | 1,041 |
| Allowance 30 coins a day | 5,913 | 6,268 / 3,282 | 635 | 3,952 | 1,524 | 24 | 1/183/372 | 589 | 13 | 1,194 |

**Findings**

**Manor reserve (B7-009):**
- More paid manor work (1,507 jobs against 662 with the caravan limit on).
- Fewer missed meals (738 against 910).
- No effect on the money supply.
- Recommendation: keep it.

**Caravan money limit (B7-014):**
- It does what it was built for. Without it, the village's money quadruples in 100 days (to about 11,600),
  the runaway growth seen under Build 7 rules.
- It also cuts what the caravan buys (941 goods against 4,221), so laborers earn less. Missed meals rise from 77 to
  738 and unemployment from 10 to 24.
- Recommendation: keep the limit, and consider a larger daily allowance (30 instead of 15). In this one run that
  allowance cut missed meals to 589, with the money supply at 5,913 instead of 11,639.
- Raising the per-head ceiling instead did not help.
- Both are owner decisions (B7-009 and B7-014 in the register).


## Build 15 (staging `a203c0b` and later, 2026-10-20): interim

**Code under test:** the Build 15 corrections:
- housing (households split on crowding);
- founding couples;
- births without a free bed (EQ-08);
- courtship (CRT-01..12);
- wildlife refuges (WR-01);
- the caravan allowance at 30 coins a day, a temporary placeholder (CARAVAN-TMP).

**Command:** `economy_sim.gd -- --days N --seed S --every 10`, with no player.

### 100 days, seed 1 (finished)

| | Day 0 | Day 50 | Day 100 |
|---|---|---|---|
| Alive | 100 | 121 | 118 |
| Starved / other deaths (cumulative) | 0 / 0 | 0 / 7 | 0 / 16 |
| Food in store (days) | 3.0 | 5.7 | 6.7 |
| Unemployed | 0 | 8 | 16 |
| Households / houses built | 24 / 0 | 27 / 1 | 28 / 1 |
| Wild / penned animals | 54 / 13 | 38 / 31 | 81 / 33 |
| Stone left (of 240) | 240 | 81 | 56 |
| Coins in the world (leak) | 2927 (0) | 5265 (0) | 6062 (0) |

**Other measurements:**
- Iron, coal, copper and gold were exhausted by day 20.
- Currency balances exactly (leak 0, holders mismatch 0), and item leaks are 0.
- Courtships reached 12. Gifts given: 96.

**At day 100:**
- 5 households were crowded and 2 couples needed a home, but no crowded household could afford one (`crowded_can_afford_home` 0). This is the open housing-growth defect under EQ-07.
- Unemployment had risen from day 40.

### 100 days, seed 2 (finished)

| | Day 0 | Day 50 | Day 100 |
|---|---|---|---|
| Alive | 100 | 122 | 133 |
| Starved / other deaths (cumulative) | 0 / 0 | 0 / 7 | 0 / 13 |
| Food in store (days) | 3.0 | 5.7 | 6.0 |
| Unemployed | 0 | 0 | 7 |
| Households / houses built | 24 / 0 | 25 / 1 | 26 / 1 |
| Wild / penned animals | 54 / 13 | 69 / 29 | 74 / 31 |
| Stone left (of 240) | 240 | 115 | 115 |
| Coins in the world (leak) | 2903 (0) | 5254 (0) | 6086 (0) |

At day 100, 6 households were crowded, and 3 of them could afford a home (`crowded_can_afford_home` 3). Even so, only one house had been finished, with a second site open. In seed 1 crowded households could not pay; here they can, but building is slow. Both point to house construction under EQ-07.

### 365 days, seeds 1 and 2 (interim; started 2026-10-20 about 00:30 UTC)

| | Seed 1, day 190 | Seed 2, day 160 |
|---|---|---|
| Alive / starved / other deaths | 125 / 0 / 22 | 137 / 0 / 18 |
| Unemployed | 26 | 16 |
| Stone left (of 240) | **0** | **1** |
| House sites started / finished | 7 / 1 | 8 / 1 |
| Wild / penned animals | 85 / 26 | 92 / 32 |
| Coins (leak) / item leaks | 7332 (0) / 1 | 7075 (0) / 1 |

**Findings:**
- Stone runs out between day 100 and day 190. A house needs 20 stone, so house sites open but are never finished. This is EQ-09 blocking EQ-07.
- Wildlife holds (WR-01).
- The one item leak is the known EQ-10 residual.

**Seed 1, day 365 (finished, old code):**
- 116 alive (100 at the start); 3 starved and 68 other deaths over the year.
- Food in store 11.2 days.
- Wildlife 91. Coin leak 0; 4 item-ledger residuals (EQ-10).
- 10 house sites started, 1 finished; 38 households.
- Stone did not stop building. The deposits were gone, yet the merchants held 97 stone at day 365, through the owner's caravan stone rule, and the open sites held 101.
- Planks did: none on the market from about day 180 to day 240, and 16 at most after that. The open sites held only 37 of the 300 they needed.
- Started houses stay unfinished. This is the second half of EQ-07, now under investigation.

**Seed 2, day 365 (finished, old code):**
- 138 alive; 1 starved and 71 other deaths.
- Food in store 3.0 days; 37 unemployed; median household cash 2.
- Wildlife 89. Coin leak 0; 3 item-ledger residuals.
- 10 house sites started, 2 finished; 40 households.

**Second root cause (found in seed 1):** from about day 120 the smith had no coal or iron and made no axes. The axes wore out (49 broken), and from day 140 no tree was felled (226 grown, no stumps). The carpenter had no logs, and planks ran out. The caravan's imported ore and coal reached the raw-goods merchant (40 of each in stock), but nothing in the code had the smith buy from the merchant; only miners ever brought ore to the forge. **Corrected:** with nothing to forge, the smith buys coal and iron ore from the merchant (`NPCBrain._smith`, test `housing_test.gd::test_forge_buys_imported_ore`).

These runs write only to `out/eq/`, which is not committed. Each result is recorded here when its run finishes. A run that a container restart killed is started again: see `docs/CURRENT_DEVELOPMENT_STATE.md`, "Fragile processes".

## EQ-07 investigation: why one house in 100 days (2026-10-20)

**Method:** `game/tests/housing_trace.gd` steps the real world (seed 2, no player) and prints every crowded, building or homeless household twice a day, with its purse, its site's remaining need, who carries for it and what is for sale. The questions are the owner's (directive 2026-10-20, Part 2).

| # | Question | Finding on the code before the fix (fix9) |
|---|---|---|
| 1 | Does the household recognize the need? | Partly. Crowding (more people than beds, two adults or more) and couples apart were checked each dawn, but nothing was kept between days. |
| 2 | Is there a decision-maker? | No explicit one. The household's first adult in member order acted. Couples were led only from the woman, so two partners of the same sex never founded a home. |
| 3 | Is a persistent goal created? | No. Each dawn started from nothing; between dawns nothing worked toward a home. |
| 4 | Is it blocked by a full-payment rule? | Not the full price. A start needed the ground and a quarter of the materials (about 82–85 coins), on top of what the family staying behind keeps (40 + 20 a member). Founders who could not meet that did nothing different, saved nothing and still bought gifts. |
| 5 | Are materials acquired? | Yes, when building runs. Materials were on sale throughout: 75–91 stone, 22–101 planks and 66–89 logs on days 0–25. The day-100 stocks were 80 stone and about 60 planks. **Stone was not the cause at 100 days.** |
| 6 | Is labour scheduled? | Yes. A helper is hired when the purse covers the rest; otherwise the founder carries. |
| 7 | Are construction tasks reachable and executable? | Yes. The one house in seed 2 was started on day 10 by a single adult with 115 coins, and bought and delivered in a day. |
| 8 | Do competing priorities prevent progress? | No evidence. Hunger and sleep come first, as they should. |
| 9 | Does construction pause and resume? | Yes. Delivered materials stay on the site. |
| 10 | Are houses completed and occupied? | Yes. The household moves in when the last load arrives. |

**Root causes:**
1. **Crowded families that no one can leave.** By day 25 of seed 2, all five crowded households had the same shape: two parents, three young children and a grandparent in 5 beds. The rules rightly never send a parent of young children away, and a grandparent does not found a household. A whole family's only way to more beds is the existing living-quarters module, which attaches only to a house on a parcel. Every original village house stands on no parcel. These families therefore never act, although some had the coins (the Mercers had 309). The diagnostic `crowded_can_afford_home` counted them as able to afford a home, which they could not use.
2. **No goal, no saving.** A grown child or couple who could not yet pay for a start changed nothing in their behaviour.
3. **Same-sex couples** never found a home (the woman-led couple loop).

**Corrections, Build 15 (agent, under the owner directive; register HOUSE-01..06, FAM-01):**
- A persistent housing goal on each household (`housing`: need, since, who decides, plan, cost, what is still to save, what it waits on). It is saved, lasts while the need lasts, and goes when the need goes.
- A responsible adult per household: a parent of someone at home first, then the eldest, of either sex. When a parent dies, the survivor decides.
- A household saving for a home buys no courting gifts.
- A crowded family nobody can leave adds living quarters to its house when the house stands on a parcel. Otherwise its goal says why it waits. Whether original houses should take quarters, or children should share beds, is the owner's decision **OD-13**.
- Couples of either sex found homes.
- No speed change, no injected coins or materials, no new building type.

**Correction to an earlier report:** the 365-day log's "stone 0" is the mine deposits, not the market. The owner's 2026-10-18 rule already brings caravan stone once deposits are low (B7-007). OD-10, raised on that misreading, is withdrawn (superseded by B7-007).

### 100 days with the housing goals (fix10: housing correction only, before the forge fix)

| | fix9 seed 1 (old) | fix10 seed 1 | fix9 seed 2 (old) | fix10 seed 2 |
|---|---|---|---|---|
| Alive at day 100 | 118 | 116 | 133 | 126 |
| Starved | 0 | 0 | 0 | 0 |
| House sites started / finished | 4 / 1 | 5 / 0 | 2 / 1 | 4 / 1 |
| Households | 28 | 29 | 26 | 28 |
| Unemployed | 16 | 16 | 7 | 5 |
| Wildlife | 81 | 75 | 74 | 76 |
| Coin leak / item leaks | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |

**Reading:**
- More households now start a home: the goals, the saving and the couples of either sex take effect.
- Started sites still do not finish within 100 days, while timber is still plentiful (about 120 planks in villagers' hands). What they wait on is being traced (`housing_trace.gd` on the corrected code).
- The forge fix matters after about day 120.

**Third root cause (trace on the corrected code, seed 1):** a single founder put all their coins into the first day's materials. A couple of days later they paired with someone whose house had a free bed, and moved in there. Their own founding household ended and the half-built house was abandoned for good; the partner's house was crowded again. **Corrected (`Life._move_in`):** a partner whose household is building its own home stays with it, and the other partner joins them, lodging where they lodge until the house stands. Two partners each building stay apart until one finishes. Test: `housing_test.gd::test_founder_who_pairs_keeps_building`.

**Fourth root cause (trace on the fix12 code, seed 2):** with the first three fixed, sites still started and stalled (by day 120–150: 7 and 9 started, 1 finished each) while planks were plentiful (108–173). A founder, Matilda, a woodcutter, put her savings into the first day's materials on day 10. Her axe then broke. From day 22 her coins stayed between 0 and 6: she spent her days "out of work: needs an axe", earning about a coin a day, so she could buy neither an axe nor materials. The job market never moved her, because she still held a woodcutter's job.

**Corrected:**
- The money a household keeps back from its building includes the price of a member's missing work tool (`Construction._tool_reserve`).
- A worker whose trade needs a tool they have not got and cannot pay for counts as out of work, so the existing job-change rules move them into paying work (`NPCBrain.tool_short`, in `seek_work`).
- Test: `housing_test.gd::test_tool_less_worker`.

### 365 days on the corrected code (fix12: housing goals, forge supply, founders keep building; before the tool fix)

Started 2026-10-20 at 01:31 UTC; recorded here when they finish.

### OD-14 Phase 1: what the original houses can take (measured 2026-10-20)

**Method:** a read-only probe on seed 1. The village layout is fixed, so seed 2 gives the same answer. For every original house held by a household (21), each house was surveyed; then every room position touching the house along at least 3 cells was tried, under the module rules:
- ground the land office would sell (no road, building, other parcel, field, pen, solid terrain or map edge);
- not covering any door step;
- a door step that is clear and reachable from the village square.

| Room size | Fits now | More once trees are felled | No legal ground |
|---|---|---|---|
| 4x5 | 3 | 0 | 18 |
| 5x5 | 3 | 0 | 18 |
| 5x6 | 3 | 0 | 18 |
| 6x6 | 1 | 1 | 19 |
| 6x7 | 1 | 2 | 18 |
| 7x8 | 0 | 3 | 18 |
| 9x10 (today's quarters) | 0 | 4, still blocked by a road | 17 |

**Which houses:** the three that can take a small room are `b23`, `b24` and `b_v1_house`, the houses beside the manor house.

**What blocks the other 18 (the most common obstacle around each):**
- the edge of the village map: 6;
- a neighbour's house and its ground: 7;
- the road: 2;
- the manor's fields: 2;
- the cow pen: 1.

These are legitimate obstacles. Removing them would mean relocating buildings or roads, building outside the map, or taking the manor's fields without a land-transfer process, all of which the owner ruled out.

**Upper floor or attic (OD-14 item 6):**
- The building system has a single level. A building is a stamp of ground, wall and roof tile layers with an interior on the same grid; the roof fades when someone is inside.
- There are no stairs, no second level, and pathfinding is one grid.
- An attic or upper floor would therefore be a major new system: multi-level maps, stairs, drawing and pathfinding.
- Under the directive it is scoped to the owner, not built (HOUSE-11).

## Script errors in every long run, and the item-ledger residuals (EQ-17, EQ-10; 2026-10-20)

**Finding.** Godot reports a script error and carries on, and the harness did not look for them, so no run
failed on one. Counting `SCRIPT ERROR` in the local logs shows them in nearly every long run since fix2:
fix9 365 days seed 1 had 20 247 from day 90; fix13 had 9 543 (seed 1, from day 140) and 8 983 (seed 2, from
day 170). Every one is `World.building_door` on a building id that does not exist. The earlier "no leak"
results stand for money and items, but the runs also had broken villagers.

**Cause** (a 160-day seed-1 run with a probe in `building_door`, first at day 142): a couple who found a
household and are still building its house lodge with family, so the new household's `home` is empty
(`Construction._found_couple`). `Life.birth` gave the baby the household's home, the empty one. The baby
then failed in every decision (`NPCBrain.decide`, bed, meals) until the house was finished. The other names
in the probe's list, the bandits, have no home by design and never reach `building_door`.

**Correction.** A baby of a household with no house yet lives where its parents lodge, and moves in with them
when the house is finished (`Construction.move_in` moves every member). Test:
`housing_test.gd test_baby_while_lodging` (fails with the same script error without the fix).

**Gate.** `.github/workflows/tests.yml` runs a 10-day simulation on every staging push (FR-07), and both it
and `long-sims.yml` fail on any script error in the log.

**EQ-10 residuals** (fix9 365 days seed 1: axe +1, hammer +2, pickaxe +1, herbal_poultice −81):
- **Tools:** whoever took over a trade got the trade's tool out of nothing (`NPCBrain._install`), although the
  late master's heir had inherited it. Now the tool passes from the heir (or the master's household); a
  newcomer brings their own and it is counted as an import (`imported_<tool>`); an apprentice with none buys
  one (`tool_short`). Test: `world_test.gd`, the village's hammers are unchanged through a succession.
- **Poultices:** villagers' use of medicine was counted only as `npc_used_<id>`, which the ledger does not read
  as consumption. It is now also `used_<id>`, as for the player.

Both wait on a 365-day run to show the ledger balanced and no script error.

## 365 days on GitHub Actions after the EQ-17 and EQ-10 fixes (run 39368663150, staging `0ee0218`, 2026-10-20)

Run 39368663150 used the manual long-simulation workflow (INFRA-02): one runner per seed, with no player, and
gated on script errors.

| | Seed 1 | Seed 2 |
|---|---|---|
| Runtime | 38.4 min | 42 min |
| Script errors | 0 | 0 |
| Currency leak | 0 | 0 |
| Item residuals | none | none |
| Fingerprint | `3e57140e93322ef7bcb411724d2249ab` | `6be5302a5ffa6f0d30307e7aa8b3ef41` |
| Villagers alive at day 365 | 101 | (in the run's artifact) |
| Starvation deaths | 0 | 2 (a merchant, day 157; an elder, day 332) |
| House sites started / finished | 7 / 0 | (in the artifact) |
| Households | 32 (8 founded) | |
| Wild animals at day 365 | every wild species present | every wild species present |
| Nights without firewood | 7,172 | |
| Meals missed for lack of money | 5,289 (hunters, carpenters) | 3,669 (hunters 4,466 missed meals in all) |

**What this verifies:**
- EQ-17: no script error in a year on either seed.
- EQ-10: the item ledger balances exactly over 365 days, tools and poultices included.
- B14R-12: wildlife no longer reaches 0; the refuges keep every species.
- Population: holds, 100 to 101 on seed 1.

**What remains (EQ-07, Build 15): house sites start but none is finished.**
- A trace (`housing_trace.gd`, 150 days, seed 1) shows why. Founders start with the 25 % start share (22-35 coins
  toward 100-140) and then cannot earn the rest. Most are single hunters, whose meat mostly finds no buyer (seed 1:
  3,957 meat made in the year, about 600 sold; 2,134 held unsold at the end).
- When four sites buy at once (day 130 on), the market's planks and logs fall to 0.
- The correction under way uses the routes the owner's housing directive lists: help from relatives (the household
  a founder came from, and the builder's parents' households, give what they can spare above their own keep), and
  next producing materials through existing crafting (sawing planks from logs).
- The hunters' income is long-term equilibrium work (Build 16, EQ-01).

## Why seed 1 builds no house: the village's trade economy stops around day 120-140 (2026-10-20)

**Corrections tried, with their 200-day results:**

| Correction | Seed 1 sites started / finished | Seed 2 sites started / finished, houses |
|---|---|---|
| None (staging `0ee0218`, Actions run, 365 days) | 7 / 0 | (the artifact) |
| Help from relatives (HOUSE-04) | 7 / 0 | 6 / 3, 2 houses |
| Plus builders make their own timber (saw, fell, buy an axe) | 7 / 0 | 6 / 3, 2 houses |
| Plus the caravan leaves tools the village needs | 7 / 0 | 6 / 3, 2 houses |

All three are approved routes and are kept. Each is tested, conserves coins and goods, and adds no script error. But
on seed 1 they cannot work, because by then the village's trade economy has stopped.

**Evidence (seed 1, 200 days, `out/eq/tool/s1.json`):**

| Day | Smith's coins | Raw-goods merchant's coins | Iron ore imported (running total) | Woodcutters | Unemployed |
|---|---|---|---|---|---|
| 20 | 155 | 362 | 96 | 4 | 3 |
| 60 | 167 | 320 | 426 | 5 | — |
| 100 | 70 | 360 | 658 | 4 | 14 |
| 120 | 0 | 391 | 685 | 4 | 14 |
| 140 | 0 | 181 | 685 (no more) | 4 | — |
| 200 | 4 | 39 | 685 | 1 | 20 |

From day 140, every good held in the village stays where it is (planks 89, logs 62: the stalled sites' deliveries).

**The chain:**
1. The mine is worked out by about day 20. Iron and coal then come only from the caravan.
2. The smith pays for them from coins above the trading floor (`NPCBrain._caravan_imports`), and the smith's coins
   run out by day 120.
3. With no iron there are no axes (`forge_axe`: iron bars and a plank). Woodcutters' axes break (40 by day 140),
   so woodcutters leave the trade (6 to 1) while unemployment rises to 20.
4. With no woodcutters there are no logs, so no planks or firewood. Builders who now have the money (100-130 coins
   with family help) find no timber to buy. They have no axe to fell their own: none is for sale.

**Where the money is instead:** on seed 1 at day 365 (Actions run), out of 8,739 coins:
- bandits held 2,365;
- 1,521 lay as loot nobody picked up;
- villagers held 3,685 (median household 54);
- the treasury held 1,148.

The traders ended broke: the carpenter, the tavernkeeper and one raw-goods merchant at 0, the smith at 16. The run
that came before all of today's changes shows the same end state, so this collapse predates them.

**Why this goes to the owner:** restarting the flow needs a choice about how money moves in the village, an economy
fundamental the overnight directive reserves to the owner. Candidate mechanisms (none implemented):
- bandits' hoards and unclaimed loot re-entering circulation;
- the manor supporting the essential trades (buying tools for the village, credit to the smith);
- the caravan buying more of what the village has in surplus (meat, hides);
- woodcutting jobs that do not depend on a market axe.

This is owner decision OD-16, with a recommendation in the register.

## 365 days with the housing corrections (staging `59057ac`, 2026-10-20)

Actions run 39385942656 (about 20 minutes a seed, against 38-42 before the PERF-04 optimizations) and local
re-runs of the same code. The local runs give the same fingerprints: seed 1 `f1a34dd03596b035a06957b6b9cb2ca5`, so
the record below holds for both. Both passed the script-error gate and the ledger: currency leak 0, no item
residuals.

| Day | Seed 1: alive / households / sites started, finished / houses / unemployed / woodcutters | Seed 2: the same |
|---|---|---|
| 90 | 116 / 24 / 0, 0 / 0 / 17 / 4 | 130 / 24 / 1, 1 / 0 / 2 / 6 |
| 180 | 128 / 30 / 6, 0 / 0 / 23 / 1 | 133 / 28 / 5, 3 / 2 / 27 / 0 |
| 270 | 123 / 31 / 7, 0 / 0 / 12 / 1 | 138 / 31 / 6, 3 / 2 / 31 / 1 |
| 365 | **111 / 40 / 13, 9 / 8** / 24 / 1 | **128 / 40 / 9, 3 / 2** / 39 / 4 |

- Starvation: seed 1 none; seed 2 four deaths in the year.
- Nights without firewood: 5,916 and 6,449 (7,172 on seed 1 before).
- Timber made: 10,308 logs and 5,202 planks on seed 1, against 6,496 and 3,364 before.

**What this settles (EQ-07):** both seeds now finish houses (8 and 2), where seed 1 finished none. The population
holds above its start, and wildlife lives all year.

**What it does not:** the trade economy still stalls for long stretches. The smith is near 0 coins from about
day 120, unemployment reaches 24-39, firewood is short, and seed 2 lost four villagers to hunger. That is the
long-term equilibrium Build 16 is for: EQ-06's acceptance is "no consistent spiral into extinction, starvation,
permanent unemployment or economic paralysis". Owner decision OD-16 is the first question there.

## 365 days on the Build 15 release candidate (staging `af60f94`, 2026-10-20)

Actions run 39396414426, and local re-runs of the same code with the same fingerprints (seed 1
`b21ba717e772664848724d5001a4028c`, seed 2 `0647d6bf82c1f58ad21f95e5aeaca583`). Both passed the script-error gate and
the ledger: currency leak 0, no item residuals.

| | Seed 1 | Seed 2 |
|---|---|---|
| Alive at day 365 (from 100) | 115 | 122 |
| Births / deaths | 84 / 69 (old age) | 92 / 70 (66 old age, 4 starvation) |
| Households | 33 | 34 |
| Sites started / finished / open | 8 / 3 / 5 | 9 / 3 / 6 |
| Houses built | 3 | 2 |
| Lofts started | 1 | 3 |
| Unemployed adults | 17 of 72 | 17 of 79 |
| Nights without firewood | 6,917 | 6,633 |
| Wild animals at day 365 | bear 2, bird 14, boar 22, deer 14, fox 6, rabbit 19, wolf 6 | bear 2, bird 18, boar 20, deer 9, fox 8, rabbit 23, wolf 7 |

**What it shows:**
- Every wild species lives the whole year on both seeds (B14R-12).
- Houses are finished on both seeds (EQ-07).
- Unemployment is lower than on `59057ac` (17 against 24 and 39).

**What stays open:**
- **Seed 1's sites stall:** its three houses were finished by about day 270, and its five other sites make no
  progress after that. Timber runs out: the logs villagers hold fall from 99 at day 90 to 14 at day 365, and planks
  from 58 to 14. No site is given up; they wait for materials. The `59057ac` run finished 9 of 13 sites; the code
  between (the guardianship, grazing and small-room changes) moves the run onto a different path.
- **No loft is finished in the year** on either seed: the beds rise only by the new houses' five each. The lofts
  started (1 and 3) wait for planks like the houses.
- **Timber and firewood** are both short. That is the timber-supply side of the economy's long-term equilibrium:
  Build 16, with OD-16 first.

## 365 days with the tool-recovery fix (staging `248e383`, EQ-18, 2026-10-20)

Actions run 39403998697, and local re-runs with the same fingerprints (seed 1 `9708e06087c100c4a19f5e08aee5c2a3`,
seed 2 `e1277ce22f0c7acd9154df745148b933`). Both passed the script-error gate and the ledger.

| Day 365 | Seed 1 | Seed 2 |
|---|---|---|
| Alive (from 100) | 98 (peak 125 at day 90) | 142 |
| Deaths | 69 old age, 1 starvation | 71 old age |
| Smiths | 2 (all year) | 2 (all year; none from day 240 before the fix) |
| Woodcutters | 2 (1 from day 180 to 300) | 2 (1 from day 180 to 300) |
| Unemployed adults | 4 (31 at day 210) | 21 |
| Sites finished / started | 2 / 8 | 6 / 8 |
| Houses built | 2 | 5 |
| Wild animals | bear 2, bird 16, boar 26, deer 10, fox 6, rabbit 24, wolf 6 | bear 2, bird 15, boar 28, deer 8, fox 4, rabbit 31, wolf 8 |

**What the fix settles:**
- The forge is never left empty: when a smith leaves, the post is taken up again.
- A job seeker can buy an axe where tools are sold.

**What it does not:** for months there is no axe to buy.
- The producing trades run out of coins. At day 180 on seed 1:
  - the two smiths hold 4 coins between them, the carpenters 6, the raw-goods merchant 28 and the tavernkeepers 0;
  - households hold 3,588;
  - the manor has taken 19,619 in tax and paid 14,048 in wages.
- The smith cannot buy ore, so iron bars run out, then axes. Woodcutting stays at one worker while 20-31 adults look
  for work, and timber, then building, stalls.
- Seed 1's population falls after day 240 as the founding generation dies of old age (42 deaths in 90 days) while
  births slow.

**Conclusion:** "economic recovery from missing work tools" (Build 15 scope) now fails on money, not mechanics.
That is owner decision **OD-16** (how money flows back to the essential trades), an economy fundamental the agent may
not decide (OVN-01 section 2). Build 15 is blocked on it.

### The determinism baseline after OD-16 (2026-10-20)

The OD-16 changes (EQ-19..21) change the village's behaviour, so `docs/release/sim_baseline.json` was re-recorded with
`tools/sim_gate.py --write` from `a6c7699`. Two runs gave the same fingerprints. Neither seed leaks coins or items at
day 10 or 30. This is a recorded behaviour change, not an optimization: the gate checks optimizations against it from
here on.

## 365 days on the OD-16 changes (staging `3e326fd`, 2026-10-20), classified under World Design Rule 022

Actions run 39408961143 and local re-runs with the same fingerprints (seed 1 `5527092958fadf428604a63bb30f18e0`,
seed 2 `e77ad22433b0e8ae660857dbc209212f`). Both passed the script-error gate and the ledger (currency leak 0, no item
residuals).

| Day 365 | Seed 1 | Seed 2 |
|---|---|---|
| Alive (from 100) | 128 | 159 |
| Starvation deaths | 0 | 1 |
| Sites finished / started (given up) | 9 / 14 (1) | 9 / 11 (0) |
| Houses built | 6 | 8 |
| Smiths / woodcutters | 2 / 1 | 2 / 1 |
| Unemployed adults | 0 | 10 |
| Treasury | 2,122 | 2,323 |
| Exported meat / hides / leather (the caravan, EQ-21) | 272 / 70 / 136 | 433 / 143 / 165 |
| Wild animals | bear 2, bird 11, boar 17, deer 11, fox 7, rabbit 25, wolf 8 | bear 1, bird 20, boar 24, deer 10, fox 6, rabbit 21, wolf 3 |

A 200-day diagnostic of seed 1 (with the read-only `od16` summary) shows all three of the owner's choices at work by
day 200:
- the manor gave out 9 axes and 2 pickaxes;
- bandits made 404 trips to the market;
- guards brought 114 coins of loot to the treasury.

The manor's advances to smiths (6) delivered no axe. A probe at days 141-161 shows why:
- smith 31 holds 8 iron ore and 6 planks but no coal, and 1 coin;
- the other smith holds one bar and 1 coin;
- the village's coal seams are worked out, so coal comes only from the caravan, and the smiths cannot pay;
- the advances went into their households' living costs.

**Classification (World Design Rule 022):**
- **Defects, fixed:**
  - the smith worked the iron for an order into other goods (`afe087c`);
  - an unmet order held its worker in the trade without a tool indefinitely, now lapsing after `manor_order_days`
    (`od16_test.gd`).
- **Legitimate outcomes, recorded:**
  - a smith too poor to buy coal after the seams are worked out;
  - one woodcutter for much of the year;
  - nights without firewood;
  - the difference between the seeds.
- **Future improvements (EQ-19, Build 16 / 17):**
  - an advance earmarked for materials, so a household does not spend it on food;
  - coal for an ordered tool bought through the manor;
  - Build 17's mining work on fuel.

## EQ-06: intervention scenarios, 100 days (2026-10-20)

**How it was run:** `economy_sim.gd -- --days 100 --seed S --scenario X --at 20` locally, on `8d3f623`'s code, on seeds 1
and 2, each against a baseline run of the same seed. No player plays. The scenario acts once, at the start of day 20.

| Scenario | What it does on day 20 |
|---|---|
| `kill_smiths` | The player kills every smith (`World.kill`, as a sword blow does): 2 on each seed |
| `corner_wheat` | A player with 3,000 coins from outside buys every sack of wheat on sale: 181 (seed 1), 367 (seed 2) |
| `gift_coins` | A player with 2,000 coins from outside gives 100 coins to the provider of each of the 10 poorest households |
| `hunt_out` | The player kills every wild deer and boar (`Fauna.kill`); the game is left lying: 19 and 20 animals |

**Integrity:** all 10 runs had 0 script errors and a currency leak of 0, with no item, deposit or animal residuals.

**Day 100:**

| Seed / run | Alive | Starved | Unemployed | Smiths | Missed meals: no money / nothing for sale | Coins in the village |
|---|---|---|---|---|---|---|
| 1 base | 120 | 0 | 11 | 2 | 208 / 137 | 6,043 |
| 1 kill_smiths | 111 | 0 | 7 | 2 (replaced) | | 5,958 |
| 1 corner_wheat | 113 | 0 | 11 | | 1,415 / 108 | 8,407 |
| 1 gift_coins | 121 | 0 | 14 | | 9 / 110 | 7,679 |
| 1 hunt_out | 118 | 0 | 13 | | | 6,011 |
| 2 base | 126 | 0 | 6 | 2 | 280 / 45 | 6,050 |
| 2 kill_smiths | 121 | 0 | 4 | 2 (replaced) | | 6,011 |
| 2 corner_wheat | 126 | 0 | 4 | | 190 / 32 | 8,515 |
| 2 gift_coins | 121 | 0 | 3 | | 7 / 32 | 7,644 |
| 2 hunt_out | 126 | 0 | 3 | | | 6,050 |

**What the village did:**
- **Killed smiths:** two other villagers took up the trade (job changes 33 and 30, against 28 at baseline). Seed 1 had
  only 28 logs at day 100 against 215 at baseline, and no house was finished.
- **Cornered wheat:** on seed 1, missed meals for want of money rose from 208 to 1,415: the wheat went to the player, and
  what was left cost more. Nobody starved. Seed 2's farms had more stock, and the effect was small.
- **Gifted coins:** missed meals for want of money fell from 208 to 9 and from 280 to 7. On seed 1 a second building
  site was finished.
- **Hunted out:** wild deer and boar were back by day 100 (seed 1: 9 deer and 13 boar, against 9 and 27 at baseline).
  The carcasses left lying spoiled, and are now counted (`spoiled_`).

**Classification (World Design Rule 022):**
- **Defects, fixed:**
  - a carcass left to spoil vanished uncounted (`World._new_day`, `world_test.gd`);
  - the player's own production was missing from the ledger, and a full pack lost it (`World.player_gain`,
    `world_test.gd`; the DVW-A7 audit).
- **Legitimate outcomes, recorded:**
  - the player's disruption has real consequences: dearer food after a corner, a timber shortage after the smiths
    die;
  - the village replaces lost trades and its wildlife recovers. No hidden protection was added (EQ-05).
- **Future improvements:** none new. Measuring a playing player's profit (DVW-A5) can use these scenarios, now that the
  player's production is counted.

## EQ-06: 365 days, seeds 1-4, no player (2026-10-20, before OD-18 parity)

Actions run 39430585149 on `8d3f623`, the code before the owner's OD-18 decisions. It is the baseline the parity work
(PAR-01..05) is compared against. Results are from the job logs: the artifacts cannot be downloaded from this workspace.

| Day 365 | Seed 1 | Seed 2 | Seed 3 | Seed 4 |
|---|---|---|---|---|
| Script errors / currency leak / item leaks | 0 / 0 / none | 0 / 0 / none | 0 / 0 / none | 0 / 0 / none |
| Alive (from 100) | 106 | 146 | 125 | 160 |
| Births / deaths of old age | 76 / 70 | 118 / 72 | 104 / 56 | 131 / 68 |
| Starvation deaths | 0 | 0 | **23** | 3 |
| Households | 37 | 38 | 39 | 49 |
| Sites finished / started; houses | 5 / 8; 5 | 9 / 11; 9 | 13 / 13; 10 | 26 / 26; 19 |
| Adults / unemployed / manor hands | 67 / 0 / 29 | 86 / 5 / 39 | 67 / 0 / 28 | 94 / 20 / 31 |
| Woodcutters / smiths | 1 / 2 | 1 / 2 | 4 / 2 | 3 / 2 |
| Nights without firewood (household-nights) | 6,852 | 6,982 | 2,962 | 5,910 |
| Treasury | 2,444 | 2,514 | 1,882 | 1,955 |
| Coins in the world (from about 2,900) | 8,778 | 9,227 | 8,987 | 9,354 |
| Wheat / meat held at the end | 2,788 / 1,693 | 7,259 / 1,559 | 2,734 / 1,938 | 1,549 / 1,902 |

**Classification (World Design Rule 022):**
- **Integrity:** every seed balanced, with 0 script errors. The simulation held on all four seeds.
- **Legitimate outcomes:**
  - each seed develops differently (5 to 19 houses);
  - firewood runs short;
  - a third of adults become manor hands once the seams are worked out;
  - seed 4 ends with 20 unemployed.
- **Under investigation (B7-015):** seed 3's 23 starvation deaths came while wheat and meat were held in stock. Whether
  those who starved had no money (a legitimate outcome) or food could not reach people able to pay (a defect) is
  checked on the parity code, which changes the rules this depends on (trade reserves, rest). Seed 4's 3 deaths are
  checked the same way.

## EQ-06 after player-villager parity: intervention scenarios, 100 days (2026-10-20)

**How it was run:** the same as the pre-parity scenarios above (`--days 100 --scenario X --at 20`, seeds 1 and 2), on
`c57b134`. That code includes PAR-01 (villager skills), PAR-02A (the dynamic reserve), PAR-03 (rest), PAR-04 (the
eleven recipes) and PAR-05 (sight and reports).

**Integrity:** all 10 runs had 0 script errors and a currency leak of 0, with no item, deposit or animal residuals.

**Day 100, against the pre-parity baseline (before -> after):**

| Seed / run | Alive | Starved | Unemployed | Missed meals: no money | Missed meals: nothing for sale |
|---|---|---|---|---|---|
| 1 base | 120 -> 123 | 0 -> 0 | 11 -> 17 | 208 -> 938 | 137 -> 62 |
| 1 kill_smiths | 111 -> 123 | 0 -> 0 | 7 -> 15 | -> 273 | -> 92 |
| 1 corner_wheat | 113 -> 111 | 0 -> 0 | 11 -> 16 | 1,415 -> 18 | 108 -> 86 |
| 1 gift_coins | 121 -> 115 | 0 -> 0 | 14 -> 11 | 9 -> 23 | 110 -> 105 |
| 1 hunt_out | 118 -> 119 | 0 -> 0 | 13 -> 16 | -> 1,178 | -> 93 |
| 2 base | 126 -> 133 | 0 -> 0 | 6 -> 5 | 280 -> 1,563 | 45 -> 7 |
| 2 kill_smiths | 121 -> 124 | 0 -> 0 | 4 -> 7 | -> 264 | -> 28 |
| 2 corner_wheat | 126 -> 120 | 0 -> 0 | 4 -> 6 | 190 -> 431 | 32 -> 45 |
| 2 gift_coins | 121 -> 128 | 0 -> 0 | 3 -> 0 | 7 -> 5 | 32 -> 48 |
| 2 hunt_out | 126 -> 126 | 0 -> 0 | 3 -> 4 | -> 1,362 | -> 46 |

(Blank "before" cells were not extracted from the baseline logs.)

**What changed:**
- **Meals missed for want of money rose about fivefold in the base runs** (seed 1: 208 to 938; seed 2: 280 to 1,563),
  while meals missed because nothing was on sale fell. On seed 1 the hunters account for most of it (151 to 886).
  - Checked and ruled out:
    - prices: hunters paid 2.0 to 2.5 coins a unit for food, against 2.0 to 3.0 before;
    - income: 791 coins for 11 hunters, against 859 for 13 before;
    - spending: 799 coins, against 813;
    - crime reports: only 13 were made in 50 days, and nobody was hungry while carrying one.
  - **The cause, found the same day** with a day-45 probe of seed 2: the goods chain from hunter to tanner to the
    caravan runs out of cash.
    - The tanners hold 27 leather and 1 coin, so nobody buys pelts or hides, and the hunters hold them unsold.
    - The caravan bought 2 leather in 100 days, against 113 before parity.
    - Its budget is finite, and the smiths' lines are served first (an earlier agent rule: they pay for ore with metal
      goods). Skilled smiths (PAR-01) now make more metal goods: 66 copper bars sold to the caravan, against 26. They
      take most of the budget.
    - The caravan also brought in fewer coins (6,260 against 8,928). With OD-19's reserves, villagers buy fewer
      imports, and the caravan's purse refills partly from what it sells.
  - **Defect found and fixed on the way** (OD-19, section 3: "business purchases may still be economically justified
    when necessary to generate income"): stock purchases had been barred outright below the reserve. A trader holding
    none of an input of their own trade may now buy one unit with reserved coins to keep earning (`World.can_afford`;
    `reserve_test.gd` 6b). Re-run: seed 1 unchanged (938), seed 2 at 4,378 money-short meals. The tanners now spend
    their last coins on pelts, and some go hungry themselves: the trader's own risk, with real consequences.
  - **Classification:** a legitimate outcome of the owner's rules (skills, reserves) meeting a finite outside demand
    and an agent-written priority order. Nobody starved; the ledger balances. **Future improvement, for the owner:**
    whether the caravan should serve its sellers in turn rather than smiths first. That is a balance change, so it is
    not made without the owner (recorded as EQ-22).
- **With both smiths killed,** two other villagers took the trade, as before. Under parity they start with whatever
  Smithing they had learned, often none.
- **A wheat corner or a gift of coins removed almost all the money-short meals:** coins from outside reach the
  households. This is the money supply question (DVW-A3) in a sharper form.

**Classification (World Design Rule 022):**
- **Integrity:** held in every run.
- **Legitimate outcomes:** the village's course differs from the baseline under the owner's parity rules, and no
  rescue was added.
- **Under investigation:** the rise in money-short meals, above.

## EQ-06 after player-villager parity: 365 days, seeds 1-4, no player (2026-10-20)

Actions run 39453456640 on `c57b134`: the parity code (PAR-01..05, PAR-02A). It predates `d18dcc1`, the
one-unit rule for a trader's input. Compared with the pre-parity baseline, Actions 39430585149 on `8d3f623`.

| Day 365 (before -> after) | Seed 1 | Seed 2 | Seed 3 | Seed 4 |
|---|---|---|---|---|
| Script errors / currency leak / item leaks | 0 / 0 / none | 0 / 0 / none | 0 / 0 / none | 0 / 0 / none |
| Alive | 106 -> 105 | 146 -> 167 | 125 -> 169 | 160 -> 126 |
| Starvation deaths | 0 -> 6 | 0 -> 17 | 23 -> 3 | 3 -> 5 |
| Households | 37 -> 40 | 38 -> 50 | 39 -> 35 | 49 -> 45 |
| Sites finished / started | 5/8 -> 11/11 | 9/11 -> 13/13 | 13/13 -> 14/14 | 26/26 -> 17/17 |
| Houses built | 5 -> 9 | 9 -> 10 | 10 -> 8 | 19 -> 12 |
| Unemployed / manor hands | 0/29 -> 0/25 | 5/39 -> 9/39 | 0/28 -> 8/33 | 20/31 -> 0/30 |
| Woodcutters | 1 -> 1 | 1 -> 5 | 4 -> 4 | 3 -> 4 |
| Nights without firewood | 6,852 -> 3,627 | 6,982 -> 3,388 | 2,962 -> 1,566 | 5,910 -> 2,856 |
| Treasury | 2,444 -> 2,130 | 2,514 -> 2,465 | 1,882 -> 2,136 | 1,955 -> 1,927 |
| Coins in the world | 8,778 -> 8,781 | 9,227 -> 9,649 | 8,987 -> 9,477 | 9,354 -> 8,898 |
| Wheat / meat held at the end | 2,788/1,693 -> 2,545/1,966 | 7,259/1,559 -> 1,974/2,030 | 2,734/1,938 -> 3,157/1,661 | 1,549/1,902 -> 3,507/2,469 |

**What changed:**
- **Firewood:** nights without firewood roughly halved on every seed. Skilled woodcutters fell more logs a tree
  (Woodcutting log_bonus) and spend less time chopping.
- **Building:** every site started was finished on every seed (one was left open before parity).
- **New goods:** villagers made the eleven formerly player-only goods and sold them on (seed 1: 84 leather caps,
  21 leather armour, 14 ploughs).
- **Starvation:** 31 deaths across the four seeds, against 26 before parity. Seed 3 fell from 23 to 3, and seed 2 rose
  from 0 to 17. As before, wheat and meat were held in the village at the time. Pattern B7-015: the hungry could not
  pay, and the goods chain ran short of cash (see the 100-day analysis above).
  - The relief rule is per household, by its food in store. Whether those who starved were outside it (no household)
    or reached it too late is being checked with a local 365-day run of seed 2, which lists the deaths.

**Classification (World Design Rule 022):**
- **Integrity:** held on every seed.
- **Legitimate outcomes:** the village under the owner's parity rules develops differently. Each seed's course differs,
  and no rescue was added.
- **Under investigation:** whether the starvation deaths are the relief rule working as written (a legitimate
  outcome) or missing someone it should reach (a defect).

### Seed 2, 365 days, after the relief valuation fix (`5625505`): the baseline for FSE-16 and FSE-17 (2026-10-20)

A local run (`economy_sim.gd --days 365 --seed 2 --every 30`) after the relief rule stopped valuing coins at a fixed
60 points (`5625505`). Kept as the baseline that the fixes since are compared with (owner, 2026-10-20: "Preserve the
existing seed-2 annual baseline").

| Measure | Seed 2, 365 days, `5625505` |
|---|---|
| Alive at the end | 130 (from 100) |
| Starved | 11 (Ivo Ford; Alice, Matilda and Ivo Lambert; Ivo, Thomas, Edith and Gilbert Fairweather and Joan Fairweather; Lettice and Sabina Dale), days 216-236 |
| Other deaths | 67 |
| Village food at the end | 11.8 days |
| Missed meals | 1,337 for want of money, 565 with nothing for sale |
| Relief | 3,218 coins spent buying food, 3,216 wheat given from the granary |
| Treasury at the end | 1,967 |
| Houses built | 8 (11 sites started, 11 finished) |
| Ledgers | coins leak 0, item leaks 0 |

**Classification:** every death is analysed in `docs/design/FOOD_SECURITY_AUDIT.md` section 2 (FSE-16). In short: all 11
qualified for relief; relief had nothing it was allowed to buy on 15 of the 36 evenings around them, and on the others
it served households in the order of their number and ran out first; the 2-coin family tab test sent people with 2
coins to vendors they could not pay while relatives held 40 or more; and villagers could not eat their own eggs or cook
their own meat, which the player can. **Defects** (fixed: the tab and the order, `9db091b`; next: the relief sources,
FSE-17, and the eating and cooking parity). **Legitimate outcomes:** the poverty of the Lambert and Dale households, the
saturated meat market, and an empty granary while the treasury sat at its reserve.

### Seed 2, 365 days, with FSE-17 and the eating and cooking parity (`69a8e14`), against the baseline (2026-10-20)

**Invalid as a measure of FSE-17 (found after it was recorded):** this run logged 634 script errors, all in
`_relief_offers` (a seller household whose home is not one of the buildings), and relief placed those pickups at cell
0,0. Fixed in `d55b6dc`; the comparison is rerun on the corrected code (local seed 2, and seeds 1-4 on Actions). The
figures below are kept as recorded, not as a result. The Actions run 39489427217 on the same commit failed on seed 2 for
the same errors.

Local run, same command. The relief order and family-tab fixes (`9db091b`), relief over every food store with one food
valuation, and villagers eating eggs and milk and roasting their own meat. **A material change; for the owner's review
before it is relied on** (owner follow-up 2026-10-20, section 4's rule applied to any change that materially affects
food).

| Measure | Baseline `5625505` | `69a8e14` |
|---|---|---|
| Alive at the end (peak) | 130 (133 at day 210) | 167 (170 at day 300) |
| Starved | 11 (days 216-236) | **23**: 2 elders on days 144-147, 2 on day 260, then 19 on days 306-320, 13 of them children |
| First starvation | day 216 | day 144 |
| Starving villager-hours | 535 | 5,817 |
| Missed meals: no money / nothing for sale | 1,337 / 565 | 31,418 / 42,030 |
| Food eaten (points) | 2.92 million | 3.35 million (+15 %) |
| Relief: coins spent / granary wheat given | 3,218 / 5,066 | 25,482 / 2,180 |
| Food held by villagers at the end (points) | 54,930 | 5,852 |
| Wheat made / held at the end | 43,920 / 2,332 | 43,920 / 884 |
| Eggs and milk eaten | 57 and 24 (they piled up: 1,636 and 1,413 at the end) | 1,630 and 1,241 |
| Roast meat made | 5,126 | 9,071 (households roast their own) |
| Unemployed at the end | 0 | 37 |
| Ledgers | balanced | balanced (coins leak 0, item leaks 0) |

(The village's "food days" are not comparable between the two: the baseline valued wheat at 20 points there, this run
at 120, the one valuation.)

**What happened.** Fed better early, the village grew about 30 % larger on the same six fields making the same 43,920
wheat (births need the household to have food in hand, and households now count everything they hold), until food per
head ran out around day 300. Relief spent eight times as much: it now buys from every store, including other
households' food above their 2-day reserve horizon. Since relief helps households under 2 days, a household that sells
down to 2 days qualifies itself as soon as it eats, so food circulates between households with the treasury paying each
time. An isolated run with that floor at relief's 3-day fill is being made to measure how much of the change this is.

**Classification (WDR-022), provisional until the comparison:**
- **Integrity:** held (both ledgers balanced; no food or coins from nothing).
- **Legitimate outcome:** a village that outgrows fixed land and then starves. It strengthens the case for land
  planning (FSE-14) and the shared farming model (OD-22); it is not answered by a rescue.
- **Under investigation:** the relief churn between households (a possible defect of the implementation's donor floor).
