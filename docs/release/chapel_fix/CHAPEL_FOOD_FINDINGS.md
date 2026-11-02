# Chapel food build-up: findings (2026-11-02)

Branch `wip/b25-chapel-food`, from `0c122b6` (the Build 25 source). Worker report for the lead; the register is not edited here.

## The finding

Year-long Actions runs on `eca0e7d` (`--market`, `shared_manor_farming=1 seasonal_village_farming=1 shared_wheat_yield=2`)
ended with the chapel holding 91,600 food points (seed 1) and 257,060 (seed 2). Wheat is 120 points a unit, so that is
about 763 and 2,142 wheat. All households together held about 18,000 points. At yield 1.5 the chapel held 0.

## Where the chapel's food comes from and where it goes (code on `0c122b6`)

In:
1. **The church plot's harvest** (`FarmPlots._store` sends the plot's crop to `Chapel.store`). The plot is 8 x 7 cells and
   gives back its own seed (`seeds_back` 1). A calendar year is 8 game days (`calendar.year_days`), and wheat ripens in one
   2-day season. Volunteers or the clergy work it every season it can be sown. At yield 2 this is **the source**.
2. Wheat offerings (`Chapel.offerings`): 10% of a household's wheat above `goods_keep_days` (6) days of food, by choice.
   Small.
3. The player's offerings. Nil in the sim.

Out:
1. Relief (`Chapel.relieve`), only to a household that **asks**. A household asks only when it has under
   `relief_trigger_days` (2) days of food, and it is filled to 3 days.
2. The player asking (`player_ask`). Nil in the sim.
3. Before this work there was **no other way out**: no spoilage, no sale, no alms in food, and no reserve limit. The coin
   fund had its X20-CHAPEL-FIX reserve and surplus alms; the food store had none.

Measured, seed 2, yield 2, 0c122b6 (baseline, local run to day 40; instrumented `CHAPEL` line):

| Day | Store (points) | Store wheat | Wheat offered (to date) | Relief given (to date) | Households asking (to date) |
|---|---|---|---|---|---|
| 20 | 29,540 | 247 | 2 | 115 wheat (9,730 pts) | 30 asks, 29 relieved |
| 40 | 60,720 | 506 | 21 | 115 wheat (9,730 pts) | 30 asks, 29 relieved |

The plot's net harvest works out at store + relief - offerings: about 360 wheat over days 1-20 (18 a day) and 240 over
days 20-40 (12 a day, with winter in the calendar). Offerings are under 1 wheat a day. Relief stops once the village is
food-secure: there were no new asks after day 20. The store then grows by the plot's whole output. The year-end
257,060 points (2,142 wheat) on seed 2 is roughly that rate less the relief given in hungry spells.

At yield 1.5 the store was 0 because hungry households asked constantly, and the plot's crop went out as relief, as
designed.

"Households sometimes missed meals": the Dispatch A record shows 6 and 17 meals missed for lack of food over the year at
yield 2. That is a few per year, not a pattern of hunger beside a full chapel. Relief went to every household that asked
(29 of 30 asks answered; the other ask came when the store and fund had nothing that fitted).

## Classification

Two parts.

**A. Defect: the chapel's store never spoiled.** DVW-B4 (approved, gentle rates): perishables spoil "wherever it is kept
(packs, pantries, granary, ...)". `Decay.dawn` covers every store except `Chapel.store`. This is fixed.

**B. Defect in part: the food store had no reserve or surplus rule.** The owner's rules are CHAPEL-R2 (2026-10-23: "offerings keep the priest, and what is
left goes as alms to the poorest households"), DVW-B3-CHAPEL ("the church's crop going to relief") and X20-CHAPEL-FIX
(2026-11-01: an operating reserve, then "surplus offerings should be distributed through charitable alms", by hardship
including "food security"; "the chapel should not function as a permanent sink"; the maturation directive's check "funds
are not hoarded indefinitely"). X20-CHAPEL-FIX was put into practice for coins only. The food store had no reserve and no
surplus path, so food beyond what askers took could never leave. Applying the same reserve-and-alms rule to the food is
an engineering correction within those rules. This is fixed (below).

**C. Outcome, and an owner policy question: the surplus no household needs.** In a food-secure village (yield 2) almost
no household is short of food: `household_food_days` counts the food a household's coins can buy, and grain is plentiful
at its floor price. So even with food alms, most of the plot's output has no one in hardship to go to. The store keeps
growing, now limited only by spoilage. The steady state is roughly inflow / 0.004, a few thousand wheat. No approved rule
says what the church should do with food nobody needs. This is not a defect: see the owner question below.

## The fix (commits on `wip/b25-chapel-food`)

1. `Decay.dawn` spoils `Chapel.store` at the ordinary rates (wheat 0.004 a day), with the stat `chapel_spoiled`.
2. `Chapel.food_alms`, run on the service day after the coin alms (`Chapel.evening`):
   - **Reserve.** `food_reserve` keeps the mean relief food given over the last `spend_weeks` (4) weeks, for
     `operating_reserve_days` (14). This mirrors the coin reserve's relief term. `relief_week` and `relief_hist` are
     saved as optional keys; an older save loads with an empty history.
   - **Who gets the surplus.** The food above the reserve goes to households below `goods_keep_days` (6) days of food,
     measured by `household_food_days` (what the household holds, plus what its coins can buy now).
   - **Who is excluded.** A household worth `alms_wealth_lines` (3) or more lines (`household_means`) gets nothing.
   - **Order.** Least wealth per member first, then the greater shortfall, then the household index. Each household is
     given up to its shortfall, once.
   - **How it moves.** Grain first, then other food, in whole units, from store to pantry by `World.transfer`. The store
     never goes below its reserve. No coins move.
   - **Why the 6-day line.** It is the line below which a household offers no wheat. Food given therefore cannot be
     offered straight back. A first version used `alms_line_days` (14). In the seed 2 run to day 40, wheat offerings rose
     from 21 to 76 against 89 wheat given, which is churn, so the line was changed.
   - **Parameters.** No new balance parameters; it uses existing provisional values.
3. Wiki: `game/scripts/core/wiki_chapel.gd`, Alms section (food shared the same way; the store spoils) and the plot
   paragraph (crop goes to relief and food alms). Manifest: new INT-674. `docs/DECISIONS.md` has a row.
4. Instrumentation (read only): the `economy_sim` `CHAPEL` line now reports `store_points`, `store_wheat`, `store_seed`
   and `food` (relief, asks, food alms, spoiled).

DCR-01 classification: a **compatible extension**. The approved reserve-and-surplus-alms rule (CHAPEL-R2, X20-CHAPEL-FIX)
now applies to the chapel's food as well as its coins, and DVW-B4's spoilage now covers the chapel's store as the rule
already said. Nothing earlier is revised: asking for relief (INT-226), the coin alms (INT-404), the plot (INT-227) and the
offerings (INT-225) are unchanged. No owner approval is needed for this part. The 6-day food line is an agent decision
(provisional).

## Tests

- `chapel_test`: 137 checks, 0 failures. New: `test_food_alms` (reserve from recent relief; none at the reserve; short
  households brought to the line; the wealthy excluded; units conserved store to pantry; no coins moved; counted; the
  relief record saved, and an older save without it loads) and `test_store_spoils`.
- `conservation_test`: 8 / 0. `net_econ_integrity_test`: 126 / 0. `migration_test`: 109 / 0. `wiki_test`: all passed.
  `tools/check_interactions.py`: 0 problems.
- `run_tests`: 3,602 checks, 0 failures, on the first version (`d08b18c`, line 14 days). It was not rerun after the
  change to the 6-day line; `chapel_test` was.

## Fingerprint (10 days, seed 1, `--every 5`)

| Commit | Fingerprint |
|---|---|
| `0c122b6` (lead's figure) | `67b6c604d4f2f83ee99132517f961630` |
| this branch | `b01fbf44fd1dc38760a9aebc15fddf5c` |
| first version (line 14) | `c0ccd2a8b9404ab6d1ae81b9469be318` |

The change is expected. On day 7 (the first service) the chapel gave 4,800 points of food to 5 households. Spoilage took
nothing from the chapel in 10 days (`spoiled` 0), so the food alms cause the difference. The day-5 checkpoint comes before
any service. Its line was not compared with a `0c122b6` run (no baseline worktree, to save disk).

## Focused runs (local, seed 2, yield 2, `--market`, shared and seasonal farming)

| Run | Day | Store (points) | Store wheat | Wheat offered | Food alms (points, households) | Spoiled |
|---|---|---|---|---|---|---|
| baseline `0c122b6` | 20 | 29,540 | 247 | 2 | - | - |
| baseline `0c122b6` | 40 | 60,720 | 506 | 21 | - | - |
| first version (line 14) | 20 | 22,820 | 191 | 2 | 7,680 / 5 | 5 |
| first version (line 14) | 40 | 54,500 | 455 | 76 | 10,680 / 14 | 30 |
| this branch (line 6) | 20 | RESULT_20 | | | | |
| this branch (line 6) | 40 | RESULT_40 | | | | |

The food alms reach households short of food, but in this food-secure village they are a small outflow. The store still
grows by most of the plot's output. Part C stands.

**Integrity note.** The first-version run stopped at day 40 with `FATAL day 40 seed 2: currency leak -4`
(`coin_sources_mismatch` -4, `holders_mismatch` 0). This change moves no coins: `food_alms` and the spoilage move goods
only. The failure has the same pattern as the `coin_sources` defect the `wip/b25-leak2` worker is fixing (2 coins at
day 180 at yield 1.5). The changed trajectory most likely reached it sooner. It is reported to the lead, not investigated
here (another worker's area).

## Owner question: what should the church do with food nobody needs?

Context: the church plot keeps producing (about 12-18 wheat a day at yield 2) in a village where almost no household is
short of food. The approved rules give its food to those who ask and, now, as alms to those short of food. The rest has
nowhere to go but spoilage.

| Option | What happens | For | Against |
|---|---|---|---|
| **1. Farm to need (recommended)** | The volunteers and clergy sow the church plot only while its store is below a ceiling, for example the food reserve plus a few weeks of recent relief and food alms. Above it the plot lies fallow and the volunteers do their own work. | No hoard and no waste. No effect on the grain market. The plot's full output returns in a famine (its store empties and it is sown again; wheat ripens in 2 days). Smallest change, in `Chapel.dawn` and `FarmPlots.plan_church`. | Volunteering stops in good years (a visible change in villager behaviour). |
| 2. Sell the surplus | The chapel sells its grain above the reserve to buyers (granary, merchants) at the market price. The coins join the fund and go out as coin alms by hardship. | The surplus becomes purchasing power for the poor (X20-CHAPEL-FIX coin alms). | Adds grain to a glutted market at the price floor, and buyers may not want it. A new selling path. |
| 3. Pass it to the manor's granary | Surplus above the reserve is given to the manor for its relief stores. | Food stays for village relief. | Blurs the church and the manor, which the owner kept separate (church first, manor second). |
| 4. Leave it | The chapel is a large famine reserve, now bounded by spoilage at a few thousand wheat. | No change. | The chapel stays a food sink in good years, against "funds are not hoarded indefinitely". |

Recommendation: **Option 1**. It keeps the owner's design: the church grows food for relief and is worked by
volunteers, and it ends the hoard without new trade or new transfers. It also takes no food out of the village economy.

## Not verified

- No year-long run of the fix. The local runs reached day 40 only, on seed 2 only.
- The year-end store under the fix is not measured.
- Not measured: the economic effect of food alms on farmers' grain sales.
- The day-5 identity against `0c122b6`.
- `run_tests` on the final commit (it ran on `d08b18c`).
- No device check.
