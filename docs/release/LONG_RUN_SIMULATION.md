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
