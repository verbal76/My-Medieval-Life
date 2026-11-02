# Farming yield calibration: the campaign plan (FARM-YIELD-D1, B25-NINE-D3)

Owner decision of 2026-11-01, Decision 3 (`docs/directives/2026-11-01_nine_owner_decisions_consolidated.md` on
`wip/requirements-control`): "Simulation-driven agricultural balancing, not an arbitrary fixed yield selection ... Select
and implement a defensible provisional baseline using simulation evidence. Retain measurement data for future balancing
... Proceed without another owner approval of arbitrary yield numbers unless a new material design conflict emerges."
Register: FARM-YIELD-D1, B25-NINE-D3, FSE-12, FSE-13, FARM-06, FARM-08.

**Status: Phase 2 done (section 8).** The decision rule chose **1.75**; the game now ships with `shared_manor_farming` 1,
`seasonal_village_farming` 1 and `shared_wheat_yield` 1.75. Sections 1-7 are the plan as written before any result; the
"Now" column of section 1 is the Phase 1 state.

## 1. The switches and what each does (Build 25 source `8dbe74f`)

| `game/data/balance.json` | Now | What it does (code) |
|---|---|---|
| `shared_manor_farming` | 0 | FSE-12, FARM-06. 1: the manor's six fields follow the player's per-cell rules (`Farming.shared_manor`): sowing takes one real seed a cell from the field's farmers' packs and then their households' pantries; a sown cell yields the wheat yield and gives back `seeds_back` seed; sowing, cutting and ploughing take the player's time a cell (`field_work_minutes`). The village starts with a field's worth of seed corn shared among each field's farmers (`Population`, world setup only). 0: the old model, 60 wheat a field (`field_yield`, about 0.9 a cell), sown without seed in 45 minutes and cut in 90. |
| `seasonal_village_farming` | 0 | FSE-13. 1: the manor's fields follow the player's seasons (`Farming.seasonal_fields`): sown only in `farming.sow_seasons` (not winter), growing at `farming.season_rate` (spring and summer 1, autumn 0.5, winter 0). 0: a field ripens `field_grow_seasons` (1) after sowing in any season, winter included. |
| `shared_wheat_yield` | 0 | FARM-08. Above 0: the wheat a sown cell yields on average, for **every** wheat cell: the player's crops (`Farming.harvest`), the households' and the church's plots (`FarmPlots.harvest_goods`), and the manor's fields when `shared_manor_farming` is 1 (`Farming.field_crop`). The fraction is resolved per cell by a hash of the cell and the day (deterministic, no RNG draw). 0: the crop's own `farming.crops.wheat.yield`, 3. Carrots, potatoes and herbs keep their own yields. |

Family plots and the player's crops are already seasonal (they use the same `season_rate`); only the manor's fields are not.
The calendar is the 8-day year (four seasons of 2 days), so 365 game days is about 45 calendar years.

**Skill and yield stay apart** (Decision 3: "Farming skill improvements must preserve the existing distinction between
faster work and crop yield"): Farming skill reaches farm work only through `CapabilityHook.time` / `work_time` (duration);
no yield function reads a skill (`farming.gd`, `farm_plots.gd`, `contract_services.gd`). The campaign changes nothing here.

**The Living Economy** is in the game but off (`game/data/economy.json` `enabled: false`, `market.drive: true`). It
switches on by default once the 13 LE-07 readiness gates pass (B25-LE-ACTIVATE-D1). `economy_sim.gd --market` runs the
shipped economy settings switched on, which is the configuration the game will ship with, so the campaign uses it.

## 2. What is already known (Build 16 evidence, `docs/design/FARM08_YIELD_COMPARISON.md`)

Actions runs 39580481791 (`cd68f58`) and 39598992347 (`02ae508`), 365 days, seeds 1-4, both switches on unless stated:

- **1.0 a cell** starves the village on every seed (5-21 deaths a seed, 12,700-31,200 meals missed with no food for sale,
  1-2 famine samples): the seasonal year is about a third short of the old model's.
- **1.5** is the smallest yield with no starvation and no famine on four seeds, but with a thin margin: it only equals the
  old model's harvest, with a winter gap the old model does not have; 2,063 cells unsown for want of seed on one seed.
- **2.0** fed every seed with no starvation and 195-306 food days held at the end. It was the agent's provisional
  recommendation, never approved.
- **2.5 and 3.0** end the year holding 19,000-35,000 wheat unsold; the extra grain is neither eaten nor exported.
- **Seasonal farming alone** (old fields) starves the village (12-50 deaths a seed): never switch it on without FSE-12.
- **Shared farming alone** at 2.0 is the same harvest rhythm with more grain and keeps every herd.
- **Wheat price** ends at the floor (2) in every run: any seller holding 14 or more asks the floor (FARM-08C). A larger
  harvest cannot lower it further.
- **Cattle**: three keeper defects were fixed (FARM-08B: whole-lot feed buying, grain locked in chests, the elderly kept as
  breeding stock). What remained was legitimate: between seasonal harvests (6-8 days apart) the keeper cannot afford
  bought feed at the floor price.

That evidence is from Build 16. Since then family farm plots (FARM-01..05, also wheat at 3 a cell, now subject to
`shared_wheat_yield`), crop sharing (FARM-CROP-01), the chapel's plot and relief, settlements and regional trade,
business ownership and the Living Economy have changed who grows, holds, sells and buys grain. The FARM-08 report's own
verification runs (its section 7) have no recorded result. So the old numbers bracket the search but cannot decide it.

## 3. The campaign: six year-long jobs in two dispatches

Every job: 365 game days, checkpoint every 5 days, the Living Economy on (`--market`), both farming switches on.
Every 5 is coprime with the 8-day year, so the 73 checkpoints fall on every day of the calendar (each about 9 times),
winter included; every 4 or 8 would sample the same season each time.

A control (switches off) is not run: the question is which yield the shared seasonal model needs, not whether the old
model works, and the decision rule (section 5) uses absolute food-security tests on each run. Context for the old model
comes from runs made anyway: 41362329381 (`908a17e`, 365 days, seeds 1 and 2, economy off) and the LE-07 readiness
run with the economy on, when it is made. Without the economy (if LE-07 is not passed), the release gate's normal-game
four-seed year runs on the Phase 2 commit test the chosen yield at no extra cost here.

### Dispatch A (4 jobs, one wave at `max-parallel: 4`)

`.github/workflows/long-sims.yml`, on `wip/b25-farming` (or the commit the lead names):

| Input | Value |
|---|---|
| `seeds` | `1,2` |
| `days` | `365` |
| `every` | `5` |
| `set` | (empty) |
| `variants` | `shared_manor_farming=1 seasonal_village_farming=1 shared_wheat_yield=1.5\|shared_manor_farming=1 seasonal_village_farming=1 shared_wheat_yield=2` |
| `sim_args` | `--market` |
| `record` | false |
| `recover_run` | (empty) |

Artifacts: `sim-v0-seed{1,2}-days365` = 1.5, `sim-v1-seed{1,2}-days365` = 2.0.

### Dispatch B (2 jobs), chosen by the rule in section 5 from Dispatch A's results

Same inputs, with `variants` a single string `shared_manor_farming=1 seasonal_village_farming=1 shared_wheat_yield=Y_B`:

| Dispatch A outcome (section 5 tests, both seeds) | Y_B | Final choice |
|---|---|---|
| 1.5 passes and 2.0 passes | 1.25 | 1.25 if it passes on both seeds, else 1.5 |
| 1.5 fails by scarcity on a seed, 2.0 passes | 1.75 | 1.75 if it passes on both seeds, else 2.0 |
| 2.0 fails by scarcity on a seed | 2.5 | 2.5 if it passes on both seeds, else no choice: a material design conflict reported to the owner (section 5) |
| 1.5 passes but 2.0 fails by scarcity (not explained by yield) | none | Dispatch B becomes the control (`variants` `shared_wheat_yield=0`, switches off, same `sim_args`) to separate the cause; no choice until it is explained |

1.0 is not retested: on Build 16 it starved all four seeds through a whole-year shortfall. The search is a bisection
of the 1.5-2.0 interval the old evidence left open, with one step outward on each side.

## 4. The measures, from lines the harness already prints

All are in the job log (the workflow greps them), so the decision does not depend on downloading artifacts.

| Measure (owner's list) | Line and field |
|---|---|
| Starvation and hardship | `day N:` lines: `alive`, `starved` (cumulative), `mean hunger`; end `food:` `starvation_deaths`, `first_starvation_day`, `starving_villager_hours` |
| Seasonal shortages | `day N:` `food X days` (days of need held by everyone, every 5 days, all calendar days); FARMLINE `famine_samples` of 73 |
| Household food access | `ECON10` per checkpoint: each household's `food_pts` and `cash`; `food:` `points_by_holder` |
| Distribution against scarcity | `food:` `missed_meal_no_food_for_sale` (nothing to buy) against `missed_meal_no_money` (food there, not affordable); `relief_grain`; FARMLINE `granary_wheat`, `farmers_wheat` |
| Prices and affordability | FARMLINE `wheat_price` (the farmers' lowest ask at the end); `ECON10` `market` (`bid_unaffordable`, `settled`) and `stats.eaff_item_wheat` (unaffordable wheat bids); `day N:` `hh cash min/med/max`; `money:` `household_cash` percentiles |
| Production and consumption | FARMLINE `farm.stats.made_wheat`, `feed_eaten_wheat`, the `wheat` ledger row (start, produced, consumed, imported, exported, end) |
| Seed | FARMLINE `used_wheat_seed`, `made_wheat_seed`, `farm_seed_saved`, `field_unsown_no_seed`, `imported_wheat_seed` |
| Storage | FARMLINE `food_days`, `granary_wheat`, the wheat ledger's end |
| Livestock feed | FARMLINE `pens` (animals, well fed, trough), `farm_made_milk`, slaughtered and starved animals; HERDLINE (cattle by day, `care` reasons: no grain for sale against no coins) |
| Trade flows | `trade:` (`exported`, `imported`, caravan coins); FARMLINE `exported_wheat` |
| Employment | `day N:` `unemployed` |
| Conservation | `day N:` `coins (leak)` and `item leaks`; any `FATAL` line; the workflow's script-error count |
| Seed differences | every measure per seed; two seeds per yield |

## 5. The decision rule (written before any result)

**Integrity (every run).** Exit 0, no script error, no `FATAL` line, currency leak 0 and item leaks 0 at every checkpoint.
A run that fails is a defect, not a yield outcome: it gives no evidence, the defect is fixed, and the lead decides any rerun.

**Food security (each run).** A run is FOOD-SECURE when all hold:

- F1. Starvation deaths over the 365 days ≤ 3 (Build 16: 0 at every secure yield, 5-21 at 1.0).
- F2. No starvation death in the first 16 days, the first two winters (`first_starvation_day` -1 or > 16): "most
  settlements should have a plausible opportunity to survive ordinary early winters".
- F3. Famine at no more than 2 of the 73 checkpoints.
- F4. Meals missed with no food for sale ≤ 1,000 in the year (Build 16: 20-188 when secure, 12,700-31,200 at 1.0).

**Classifying a failure.** A run that is not FOOD-SECURE is classed:

- **SCARCITY** when `missed_meal_no_food_for_sale` ≥ `missed_meal_no_money`, or when `food X days` is below 1.0 at the
  checkpoints before the starvation deaths. Only scarcity counts against a yield.
- **ACCESS** when `missed_meal_no_money` > `missed_meal_no_food_for_sale` and the village held at least 3 days of need at
  those checkpoints: food existed but people could not buy or reach it. Per Decision 3 ("Do not solve a transportation or
  purchasing defect by artificially increasing crop yields") this does **not** raise the yield: the yield is judged as if
  the run were secure, and the access failure is reported to the lead as its own finding (affordability, distribution or
  a defect).
- **UNRESOLVED** otherwise: the lead examines the run's `sim.json` before any choice.

**Choice.** The baseline is the **lowest tested yield that is FOOD-SECURE (or fails only by ACCESS) on both seeds.** The
lowest such yield is the most challenging one that still lets ordinary villages survive; nothing above it is needed for
survival, and the Build 16 evidence shows more grain above that point ends unsold rather than eaten or sold away.

**Secondary checks on the chosen yield (reported; may move the choice one step up only as stated).**

- Livestock: if the cattle die out on both seeds and HERDLINE's care reasons are mostly no grain for sale (feed scarcity),
  take the next tested yield up. If they are mostly no coins, it is an affordability finding (as FARM-08B 5.3), reported,
  and the yield stays.
- Seed: `field_unsown_no_seed` above 10 % of the seed sown on both seeds is a seed-distribution finding, reported, not a
  reason to raise the yield (Build 16: seed shortfalls were not tied to the yield).
- Glut and prices: the end food days, the wheat held unsold and the end price are reported for the owner's later balancing.

**When to stop and ask the owner.** No tested yield up to 2.5 is secure by scarcity on both seeds; or the chosen yield
needs a rule change outside the yield (granary sales to keepers, feed rules, the price floor). These are material design
conflicts under Decision 3.

## 6. Continuity notes (DCR-01)

- **The player's wheat changes.** `shared_wheat_yield` is one value for every wheat cell, so the player's and the
  households' wheat moves from 3 a cell to the chosen yield. FSE-12's owner wording: "Do not arbitrarily increase village
  yields or decrease player yields just to make the numbers match." The choice here is made by the evidence rule above,
  not to match totals, and the owner's 2026-10-21 direction asked for shared values between 0.9 and 3: a **compatible
  extension**. The wiki's farming pages must state the new yield in Phase 2.
- **Both switches together.** Seasonal farming alone starved the village on Build 16; the campaign and the outcome
  switch both on or neither.
- **Old saves (Phase 2 item).** The seed corn is given at world setup only (`Population`), so a save made with
  `shared_manor_farming` 0 and loaded after the switch has farmers without seed corn: their fields stay unsown until seed
  is bought or saved. Phase 2 must test a loaded old save and decide (agent detail, documented) whether the load gives the
  same seed-corn start or relies on the existing seed purchase; never a silent rescue.

## 7. Local smoke tests (Phase 1, `8dbe74f` plus the harness fix below)

10 days, seed 1, every 5, `XDG_DATA_HOME` and `TMPDIR` in a scratch directory, after one `--import`.

| Variant | Exit | Script errors | Leak / item leaks | Wheat made | Wheat seed used / saved | Day 10: alive, starved, food days, mean hunger |
|---|---|---|---|---|---|---|
| `shared_wheat_yield=0` (control), economy off | 0 | 0 | 0 / 0 | 1,080 | 264 / 0 | 109, 0, 4.1, 66 |
| `--market` alone, before the fix | 1 | 0 | **-19** / 0 | 1,080 | 233 / 0 | 105, 0, 4.0, 65 |
| `--market` alone, after the fix | 0 | 0 | 0 / 0 | 1,080 | 233 / 0 | 105, 0, 4.0, 65 |
| both on, 1.5, `--market` | 0 | 0 | 0 / 0 | 954 | 1,059 / 396 | 106, 0, 3.5, 67 |
| both on, 1.75, `--market` | 0 | 0 | 0 / 0 | 1,056 | 1,020 / 396 | 105, 0, 3.2, 64 |
| both on, 2.0, `--market` | 0 | 0 | 0 / 0 | 1,152 | 1,047 / 396 | 108, 0, 3.5, 68 |
| both on, 2.0, economy off | 0 | 0 | 0 / 0 | 1,152 | 1,041 / 396 | 110, 0, 3.8, 70 |
| both on, 2.5, `--market` | 0 | 0 | 0 / 0 | 1,350 | 1,024 / 396 | 107, 0, 4.9, 68 |

The settings take effect: with the switches on, seed is sown a cell at a time (about 1,050 against 233-264) and saved
back (396), and the harvest scales with the yield. `shared_wheat_yield=0` gives the same fingerprint as no setting
(`311fef9d...` for `--market` with and without it), so it is a valid control string.

**Harness fix (test code only).** With the economy on, `economy_sim.gd`'s list of coin holders (`_coins`) lacked the LE-05
paid-repair escrow (`economy.repairs.escrow()`), which `World.total_coins` counts. Any checkpoint with a repair paid for and
not yet done showed a false currency leak and stopped the run with `FATAL` (seed 1, day 10: 19 coins, exactly the
escrow). Every `--market` year-long run would have risked this. The holder is now listed; the fix only reads, and the
day-10 fingerprint is unchanged (`311fef9de8d5e39a82d118e9bb739754` before and after).

## 8. Phase 2 result (2026-11-02)

**Decision by section 5.** Dispatch A: 2.0 passed on both seeds; 1.5 failed by **scarcity** on seed 1 (Actions
41403541582). That is the table's second row, so Dispatch B tested 1.75. 1.75 is FOOD-SECURE on both seeds (Actions
41469335443), so the baseline is **1.75**, the lowest tested yield secure on both seeds.

| Run (365 days, `--market`, both switches on) | Starved | Famine samples | Meals missed, no food for sale | Lowest food days | Integrity |
|---|---|---|---|---|---|
| 1.75, seed 1 | 0 | 0 | 326 (319 of them night guards, days 90-150) | 3.0 | clean |
| 1.75, seed 2 | 0 | 0 | 7 | 3.0 | clean |
| 1.5, seed 2 | 0 | 0 | 10 | 2.6 | clean |

Integrity clean: exit 0, no script error, no `FATAL`, currency and item leaks 0 at every checkpoint. All three meet F1-F4
(F4: 326 against the 1,000 limit). Seed 1's missed meals are almost all night guards in one stretch (days 90-150), a
distribution pattern for the lead to look at, not a yield shortfall: food was held throughout (never below 3.0 days).

**What changed in the game (Phase 2 commit).**

- `game/data/balance.json`: the three values, with a `_shared_farming_note` citing this report.
- Every wheat cell, the player's, the households', the chapel's plot and the manor's fields, yields 1.75 on average
  (`Farming.cell_yield`: 2 or 1 by a hash of the cell and the day; a manor field `round(sown x 1.75)`). Carrots, potatoes
  and herbs keep their own yields. The player's harvest action now names the cell's own crop instead of the crop's base 3.
- The wiki (`wiki_farming.gd`, `wiki.gd`): the wheat line states the shared yield; the farming page, the farmer's job and
  the wheat field say the manor's fields are sown a seed a cell, in season, at the same yield.
- **Old saves** (section 6; agent decision in `docs/DECISIONS.md`, 2026-11-02): a save without the `shared_farming_start`
  key (made with the old model) is moved once on load by `World.start_shared_farming`: each field's farmers are given its
  seed corn, the start a new world gets (`Farming.give_seed_corn`, shared with `Population`); a field growing under the old
  model counts as sown whole and keeps its growth; the key is saved so it never repeats, with a stat and a log line. Seed
  purchase alone could not do it: farmers buy only up to `seed_keep` (2) and hold at most `seed_cap` (12) against a
  field's 66 cells. Tested by `game/tests/farm_shared_save_test.gd` on the Build 24 fixture.
- Tests with stale expectations of the old defaults: `farming_test` (a farmer's starting seed now includes their share of
  the field's seed corn; the player's harvest is the cell's shared yield, not 3), `farm_plots_test` (the player's and a
  family's harvest at the shared yield), `crop_share_test` (the old seed-keeping rule now sets `shared_manor_farming` 0
  itself and restores the setting, instead of assuming it is off). `wiki_test` checks the farming page's yield and manor
  field text. `world_test`'s FSE-12/13 checks already set and restore their switches and pass unchanged.

**Kept for later balancing** (section 5, secondary): the end food days, wheat held unsold, the end price, cattle and seed
measures of the four Dispatch A runs and the three Dispatch B runs are in their job logs; Phase 2 changes no rule outside
the yield.

