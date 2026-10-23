# REC-F1: the repeated decision loop of villagers holding unsold goods

Owner decision: `docs/directives/2026-10-23_recf1_storage_decisions.md`. Branch `wip/fix-recf1` (from `wip/expansion19-preparation`
4a0459f). Evidence: flight-recorder 10-day archive, seed 1 (day 9: p:5, p:87, p:50, p:18, p:67, p:13 made 400-600 `plan_next`
decisions for 4-19 actions; hourly `doing` was "holding unsold pottage/log/stone/feathers").

## Cause

1. `NPCBrain._plan_sell` (`game/scripts/core/npc_brain.gd`, "holding unsold") has no buyer: it sets `doing = "holding unsold X"`
   and the plan `[work(30, "", {}, "idle")]` - a 30-game-minute wait, which is the intended behaviour.
   `_woodcutter` ("waiting for trees to grow", `[work(60, ...)]`) builds its wait the same way.
2. `World._run_plan` (`world.gd`) executes a `work` step by counting `n.work_left` down. `work_left` is loaded from the step's
   `min` only at two points: when a `go` step arrives (`_walk`, `plan[1].k == "work"`) and after a `do` or finished work step
   whose next step is work. A plan that **begins** with a work step is never loaded.
3. So the wait inherited `work_left` from the previous step, which has always run down to <= 0 (it is not reset when a step
   ends). `n.work_left -= gm` stayed <= 0, the step was popped on the very first tick, the plan was empty, and
   `World._update_npc` called `brain.decide(n)` again on the next tick. The 30-minute wait occupied one tick (0.5 s real,
   one game minute); decide() re-ran every tick and chose the identical "holding unsold" plan until the work day ended.
   This is the loop of hundreds of decisions: each villager with unsold stock and no buyer decided about once per game
   minute for the working day (up to ~600 a day), and the count grew as unsold stock spread to more producers.
4. Why nothing productive was chosen: not a refusal rule. `_plan_sell_all` / `_miner` / `_woodcutter` / `_plan_job` return the
   "nobody buys it" plan on purpose when the carried stock is at its limit and no buyer exists; the intended outcome was a
   30-minute wait, then a fresh look. Production rules, prices and demand are as designed; only the wait's length was lost.

Not a cooldown: no timer, counter or memory was added. The existing wait now lasts the minutes the plan already states.

## Correction

`NPCBrain.wait(n, minutes)` builds a lone wait step and loads its `work_left`. Used by the two lone-wait plans above
(`_plan_sell` no-buyer, `_woodcutter` waiting for trees). Nothing else changes: when the wait ends, decide() looks at
buyers, needs, work and hunger afresh, so a buyer who appears is served at the wait's end (at most 30 game minutes), and
hunger, a report, a fight, the evening and sleep still interrupt through the usual routes (the plan is cleared by them).

Plans that begin with a work step and share the stale-count pattern but are instantaneous by design/effect were left alone
(isolated change): the one-step `eat`/`use_medicine` acts (`work(10, "eat")`, which finish at once today) and `_plan_bed` for
a villager with no home. Changing them would alter eating and rest timing. Candidates for a separate decision.

## Evidence (10 days, no player activity, `game/tests/recf1_measure.gd`)

| seed | decide() calls days 0-9, before | after | day 9 before | day 9 after | villagers with 400+ decisions on a day |
|---|---|---|---|---|---|
| 1 | 51,149 | 21,816 | 8,360 | 2,015 | many -> none (max 291, one day) |
| 2 | 55,922 | 21,219 | 9,184 | 1,943 | many -> none |

Decisions per day are flat (about 2,000-2,400) instead of rising from 2,100 to 8,300. Actions (seed 1 / seed 2, 10 days, before ->
after): sell_to 1249 -> 1303 / 1143 -> 1163; craft 689 -> 744 / 613 -> 634; mine 607 -> 657 / 583 -> 586; chop 183 -> 185 / 188 -> 182;
hunt 48 -> 37 / 14 -> 14; eat 122 -> 145 / 128 -> 116; made_pottage 1542 -> 1555 / 1633 -> 1656; made_plank 366 -> 436 / 381 -> 358;
eaten_food 70,606 -> 72,943 / 69,562 -> 71,144. Work, trade and production are not suppressed (equal or slightly higher; the
runs diverge from day 0 because decide() consumes the RNG, so exact equality is not expected). Deaths by day 10: 8 -> 4 (seed 1),
10 -> 7 (seed 2). Currency and item ledgers: leak 0. Seed 1 `poach` rose 642 -> 1219 because the bandits survived longer
in the changed trajectory; unrelated code.

Tests: `game/tests/recf1_test.gd` (fails without the correction on 2 checks, passes with it); `world_test`, `parity_test`,
`interdependency_test`, `stalls_test`, `od16_test`, `conservation_test`, `succession_test` pass.

Determinism gate (`tools/sim_gate.py`, not re-baselined): differs at the first checkpoint (day 10) for both seeds, as expected
for a gameplay change; decide counts already differ on day 0 (2,400 -> 2,176) because the first no-buyer wait now lasts 30 minutes.
