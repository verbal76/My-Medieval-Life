# Build 18 365-day runs: report (REL18-LONGRUN, WDR-004-C, SET-C, REG-EVAL-01)

Run 39874405723 (`long-sims.yml`), `wip/build18` at `9a86f5c`, `economy_sim.gd --days 365 --every 10`, seeds 1-4, one run per
seed. All four jobs exited 0. Analyst: read-only; no code changed, nothing run, nothing committed.

## What the logs contain, and what is missing (read this first)

The job log does not hold the simulation's output. The workflow (`long-sims.yml`, "Simulate" step) writes `sim.log` and
`sim.json` into the artifact and prints only: `summary.json` (end-of-run values), `FARMLINE`, `HERDLINE`, and `tail -n 30
sim.log` (the last rows of the item table). The artifact storage host is blocked from this machine, as for the Build 17 report
(`docs/build17/MIN_G_LONG_RUNS.md`, which met the same limit).

Consequences, stated plainly:

| Asked for | Available? |
|---|---|
| FATAL lines, leak, script errors, day reached, runtime, fingerprint | Yes (summary and exit state), except the printed `LEAKS:` line (it is above the last 30 log lines) |
| Per-checkpoint table at days 10, 30, 100, 200 (people, currency, treasury, food days, unemployment) | **No.** Only day 365 is in the logs. The day-100 read (SIM-01) cannot be made from these logs. The checkpoint lines are in `sim.json` / `sim.log` in the artifact (seed 4: artifact id 12470533593) |
| The five settlements' coins and population over time, migration, SET-D business openings and closings | **No.** They are printed only on the per-checkpoint `neighbours:` and `migration` lines and in `sim.json`. The summary has none |
| Village-to-settlement trade | Only the village's whole-run outside coin flow (currency block), which mixes sources |
| Final-state production, stocks, events, work, building, farm and herd | Yes |

Sections 2, 5 and 6 are therefore answered only as far as end-of-run values allow. Whoever can open the artifacts (the owner, or
a session with artifact access) should read `sim.json` `samples[]` (fields `people`, `food`, `work`, `money`, `regions`, `growth`)
for days 10/30/100/200 before REL18-LONGRUN, SET-C, SET-D and REG-EVAL-01 are closed. I did not try artifact downloads.

## 1. REL18-LONGRUN: integrity per seed

| Seed | Job | Runtime | Exit | Script errors | Currency leak | Item leaks | FATAL | Reached day 365 | Final fingerprint |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 120156402386 | 6,776 s (113 min) | 0 | 0 | 0 | none (`{}`) | none | yes | `7bb401e9e8c026b083dd3026cfa7c0f2` |
| 2 | 120156402285 | 7,983 s (133 min) | 0 | 0 | 0 | none | none | yes | `64de918138f545ed6d32651f2f4bed9e` |
| 3 | 120156402359 | 6,481 s (108 min) | 0 | 0 | 0 | none | none | yes | `614c50eacf3b4c5fdb15b26129568bc2` |
| 4 | 120156402408 | 4,458 s (74 min) | 0 | 0 | 0 | none | none | yes | `79c907e32e158e2108bcb9c4ae14ef16` |

Evidence for each cell:
- Leak and items: `summary.json` `currency.leak` = 0, `currency.coin_sources_mismatch` = 0, `currency.holders_mismatch` = 0,
  `item_leaks` = `{}` in all four. The sim exits non-zero on a currency or item leak, and every exit code is 0.
- FATAL: none in the last 30 log lines of any seed. A FATAL stops the run at its checkpoint; every run has `samples` = 38 in
  FARMLINE (start sample + days 10..360 + day 365), so the run went to day 365. A settlements-books FATAL (`regions.audit`,
  coins/goods/people mismatch) would also have stopped it early, and none did. I could not read the printed `LEAKS:` line
  itself; the values above stand in for it.
- Script errors: `script_errors` = 0 (the workflow counts `SCRIPT ERROR` lines in `sim.log`).
- Godot exit noise in every log: "N ObjectDB instances were leaked at exit" (1,598 / 1,568 / 1,664 / 1,512) and "38 resources
  still in use at exit". Engine shutdown messages after the result was written; not counted as script errors. Whether Build 17
  logs carried the same I did not check.
- Runtimes: Build 17 runs (MIN-G) took 66-118 min; these took 74-133 min (seed 2 longest in both).
- Determinism: one run per seed (SIM-01). No second run exists to compare fingerprints with, so none is claimed.

## 2. Checkpoints

Day-365 values only (the other checkpoints are not in the logs). Day-90 row is the earlier baseline (seed 1, commit `36beb67`,
`docs/investigations/evidence_2026-10-23_regional/economy_sim_90d_seed1_36beb67.log`, a different commit), and Build 17 day-365 is
from `MIN_G_LONG_RUNS.md` (commit `7e19008`).

| Seed / day | Alive | Households (counter) | Village coins (total) | Of which villagers / chapel / treasury | Food days | Starvation deaths | Adults | With job | "Unemployed" |
|---|---|---|---|---|---|---|---|---|---|
| 1 / 365 | 397 | 28 | 8,691 | 817 / 7,375 / 4 | 20.9 | 0 | 235 | 47 | 188 |
| 2 / 365 | 310 | 29 | 7,469 | 906 / 5,099 / 2 | 37.2 | 0 | 168 | 46 | 122 |
| 3 / 365 | 329 | 26 | 8,949 | 806 / 7,119 / 2 | 27.3 | 0 | 183 | 48 | 135 |
| 4 / 365 | 338 | 31 | 8,919 | 823 / 7,466 / 0 | 27.1 | 0 | 167 | 43 | 124 |
| Baseline 1 / 90 (36beb67) | 129 | 26 | 7,717 | not split | 17.0 | 0 | n/a | n/a | 14, treasury 498 |
| Build 17 / 365, seeds 1-4 | 159 / 166 / 133 / 173 | 33-35 | 9.2k-9.7k | no chapel then | 55.5-203.9 | 0 / 1 / 0 / 0 | 83-104 | about 74-80 (derived) | 9 / 21 / 6 / 30 |

Day 10, 30, 100, 200: not available from the logs (see top). Start values of the sim (same for all seeds): 104 alive, 25
households, about 3,000 coins (start_total 3,009 / 2,966 / 2,942 / 3,057), 748 wheat.

Other end-of-run facts per seed:

| Seed | Births counter | Old-age deaths | Elders / children | Missed meals (no money / no food for sale) | Relief grain | Mean hunger | Net outside coins into village (in - out) |
|---|---|---|---|---|---|---|---|
| 1 | 487 | 91 | 32 / 130 | 82 / 3 | 477 | 71.1 | +5,682 (9,479 - 3,797) |
| 2 | 453 | 86 | 23 / 119 | 348 / 6 | 267 | 71.3 | +4,503 (9,879 - 5,376) |
| 3 | 520 | 96 | 14 / 132 | 50 / 32 | 309 | 70.2 | +6,007 (9,027 - 3,020) |
| 4 | 445 | 73 | 23 / 148 | 16 / 7 | 366 | 71.0 | +5,862 (9,486 - 3,624) |

The "births" counter is `npcs.size() - start.npcs`, so it also counts newcomers and any other person added to the world, not
only babies. "Households" is `w.households.size()`, which includes ended households. Read both as upper bounds.

Facts: no starvation death in any seed (food block `starvation_deaths` 0, `famine_samples` 0). Population ended at 3.0 to 3.8 times
its start. All deaths are "old age".

## 3. Unemployment: what the counter counts

Exact definition (`game/tests/economy_sim.gd`, `_sample`, around lines 553-566): loop over living villagers; for each NPC with
`role == "adult"`: `adults += 1`; `if n.job != "": with_job += 1`. Then `unemployed = adults - with_job`.

So it counts **adults whose `job` string is empty**. Details that follow from the code:
- Children (`role "child"`) and elders (`role "elder"`) are not in it. Retired elders have their job cleared on retirement
  (`life.gd` ~205) and are excluded by role. The 124 in seed 4 are the `(adult)` row of `by_job`; `(elder)` (23) and `(child)` (148) are separate.
- Anyone with any job, including farmer, manor hand, woodcutter, merchant, clergy, counts as employed. A person working a household plot
  is counted as employed only if their `job` is "farmer"; a household member tending its own plot with no job is in the counter.
- A household living on savings or a spouse's income is in the counter if the person has no job. The counter is not about income.
- A child who comes of age becomes `role "adult"` with the job left empty (`life.gd` ~227, "comes of age": no job is set). They enter
  the counter on day one and stay until `seek_work` places them. So population growth feeds the counter directly.
- Quirk: `with_workplace` equals `with_job` in all four seeds (47/47, 46/46, 48/48, 43/43).

How jobs are found (`npc_brain.gd` `seek_work`, `job_market`): every morning each no-job adult takes the best opening from a fixed list
(manor_hand, farmer, woodcutter, hunter, miner, prospector, stonecutter, tailor, barber, preacher, church_assistant). The number of
openings is computed, not unlimited:
- manor_hand openings = `(treasury - reserve) / (wage x 20)` (balance: wage 6, `manor_hire_runway_days` 20, reserve = 10 days of
  obligations). At the end of the runs the treasury is 4, 2, 2, 0 coins, which gives 0 openings in every seed.
- farmer openings = `field_workers_max (2)` x fields (6) = 12. Farmers are exactly 12 in all four seeds.
- woodcutter, hunter, miner openings follow trees, game and ore left; tailor, barber, preacher, church assistant are single places.
- The merchants (6), smiths (2), carpenters (2), tanners (1-2), cooks (2-3), tavernkeepers (1-2) hold fixed places. Those counts are
  the same size in all four seeds and the same as the start, and are filled only by succession.

Counter over time:
- Day 365: 188 / 122 / 135 / 124 (seeds 1-4), i.e. 80% / 73% / 74% / 74% of adults.
- Baseline seed 1 (earlier commit): 0 at day 0, 3 at day 30, 7 at day 60, 14 at day 90 (11% of adults at most).
- Build 17 day 365: 9 / 21 / 6 / 30 of 83-104 adults (6-30 adults, register item B17F-JOBS, deferred to Expansion 20 by the owner).
- Intermediate days in this run: not in the logs.

The number employed went down relative to Build 17 (about 74-80 derived there, 43-48 here) while adults roughly doubled (83-104 to
167-235). The job count is the same in all four seeds (12 farmers, 6 merchants, a handful of others), which points at fixed place
capacity rather than at each village's luck.

Classification:
- **Outcome, not a counting artefact:** the counter measures what its name says (adults with no job), and the code gives the
  structural cause: a village with 6 fields, a fixed set of trades and an empty treasury has about 45 places for 167-235 adults. No
  new fields, trades or stalls opened in the year (building: 1-3 houses; no stall relocations; `wage_offers_raised` 0).
  Under WDR-022 unemployment is an outcome to report.
- Interpretation (not shown directly): the large number is the result of population growth outpacing a fixed job structure,
  plus a manor treasury that is near zero. The treasury at day 90 in the baseline was 498; it is 0-4 at day 365. When it fell is not
  in these logs.
- **Possible defect: needs root-cause check (low confidence):** that 122-188 adults hold no job while the treasury is empty and the chapel fund holds
  5,099-7,466 coins (68-85% of the world's coins; section 4) and wheat stock rises to 16-25k. Nothing says this breaks an approved
  rule; the question is whether coins that leave circulation for the chapel starve the manor's wage fund (the only source of
  open manor-hand places). Also `with_job` (43-48) is lower than Build 17's (about 74-80): worth confirming which jobs went (needs
  the `by_job` of Build 17 day 365, not in `MIN_G_LONG_RUNS.md`).

## 4. WDR-004-C scarcity audit

The 100-day column is not available (no checkpoint data). The table compares the 365-day end state with what the baseline (90-day,
earlier commit) and Build 17 (365-day) record. Where the 100-day read is needed it is marked "not in logs".

| Area | Day 100 | Day 365 (this run) | How the world responds to scarcity (facts) |
|---|---|---|---|
| Wheat supply | not in logs | made 79.6k-83.0k, eaten/used 57.9k-67.0k; stock 748 -> 15.9k / 24.7k / 16.6k / 18.9k; farmers' hands hold 1,865-2,264 | No wheat shortage. A surplus builds, stock increases about 21-33 times. Wheat price 2 in all seeds. |
| Food days | baseline 17.0 | 20.9 / 37.2 / 27.3 / 27.1 | Build 17: 55-204. Lower, still above the 10-day household runway. No `famine`; `famine_samples` 0 |
| Starvation | none (baseline) | 0 in all seeds | Build 17 had one (seed 2). Missed meals for lack of money: 82 / 348 / 50 / 16 (Build 17: 606 / 879 / 2,012 / 5,417); for lack of food for sale: 3 / 6 / 32 / 7 |
| Relief | n/a | grain relief 477 / 267 / 309 / 366 | Relief exists and was used; it was not what kept the villages alive (stock surplus) |
| Wheat seed | n/a | no unsown field for lack of seed (`field_unsown_no_seed` 0); 35-59 seed imported | Seed saved 549-784, imported 35-59 from outside: a small outside dependency, not a shortage |
| Animals | not in logs | cows survive in all seeds (5 each, born 115-120, surplus slaughtered 113-118). Chickens: extinct in seed 2 (8 eggs all year) and seed 3 (552 eggs, 0 hens at the end); 12 in seeds 1 and 4. | Same chicken extinction as Build 17 (seeds 2 and 3). Deferred by the owner (B17 finding). Cows: `keeper_no_feed_cow` 39 / 17 / 12 / 2, `keeper_no_coins_cow` 39 / 16 / 11 / 2: the keeper could not feed the pen on those days |
| Firewood | n/a | household-nights without logs: 3,057 / 3,417 / 3,325 / 4,465 | Roughly 30-40% of household-nights (about 11,000 per seed). The harness counter sums `world.gd` "N households had no firewood", which loops over `households`, **including ended households that can never hold a log**, so the true figure is lower; by how much is not in the logs. Possible counter defect: needs root-cause check. Cold has no recorded effect in these logs |
| Ore / seams | baseline: iron and coal exhausted by day 45, copper 33 left, stone 280 | seams worked out 26 / 22 / 20 / 22 | Ore ran out in the first year; miners 3-5 kept their jobs. Pickaxes and shovels sold or made (pickaxe made 14-32); stone made 325-646, used 179-455 |
| Tools | n/a | tools broke 14 / 12 / 15 / 10; pickaxes made 14-32 | Tools were replaced (made, not lost); `manor_tool_coins` 499-1,357 |
| Timber | n/a | planks made 1,728-2,988, 106-191 left; `timber_support` used 7-12 | No plank shortage shown |
| Trade | n/a | caravans 182 in each seed (one every 2 days, as set) | The caravan comes on schedule. Outside coin in 9.0k-9.9k; out 3.0k-5.4k |
| Wealth | start about 3,000 | villagers hold 806-906 coins total (2.1-2.9 per person); chapel 5,099-7,466; treasury 0-4; bandits 19-35; loot 386-1,352; stall tills 55-70 | Money moved out of villagers' purses into the chapel's offering fund. See below |
| Employment | baseline 90: unemployed 14 | 43-48 employed | Section 3 |
| Production | n/a | pottage made 95k-120k; roast meat 1.3k-1.6k; red berries 1.2k-1.5k | Food output is large; flat ratio to population not computable without checkpoints |

Notes on scarcity response (facts, then interpretation):
- The world responds to wheat scarcity before the run starts (day-0 food 3.0 days in the baseline) with no starvation and a growing
  surplus. Fact: the ledgers show growth in wheat and wheat seed stock, not drawdown.
- Wealth. Fact: the chapel fund (offerings: `coin_share` 0.3 of coins above reserve and `keep_coins` 8, weekly, from villagers at or
  above `min_piety` 0.3) pays out only the clergy wage and church relief purchases. At day 365 it holds 84.9% / 68.3% / 79.6% /
  83.7% of all coins in seeds 1-4. The villagers hold 2-3 coins per head. This is allowed by the owner's chapel design (provisional
  numbers); the effect on the manor treasury (0-4 coins) and on job openings (section 3) is interpretation.
- **Possible defect: needs root-cause check:** the church-first relief is meant to feed households in need; seed 2 records 348 missed
  meals for lack of money while its chapel holds 5,099 coins. Whether the relief's qualifying rule leaves these households out (a
  rule, not a fault) or fails to reach them is not in the logs.
- Ore and stone: the 20-26 seams worked out by day 365 mean the first-year deposits are exhausted. The logs do not show what
  miners do afterwards; `miner` jobs stay at 3-5.

## 5. SET-C and REG-EVAL-01: the regional economy

Not answerable from these logs for the settlements' coins and population (printed only on the `neighbours:` and `migration` lines
in the artifact). What the logs do show:

- Whole-run outside coin flow of the village (`currency`): in 9,479 / 9,879 / 9,027 / 9,486 coins, out 3,797 / 5,376 / 3,020 / 3,624,
  net +5,682 / +4,503 / +6,007 / +5,862 (seeds 1-4). `coin_sources_delta` equals this net in every seed.
- "In" mixes caravan purchases and newcomers' purses (`newcomer_coins` 60 each, new money by the ledger) and "out" mixes the village's
  purchases from the traders, luxuries and other caravan sales. It cannot be split into settlement trade from the summary.
- Baseline (90 days, seed 1, `36beb67`): the settlements' coins fell 9,249 -> 4,610, the village's net intake was 4,639 (4,927 in,
  288 out). Here, over 365 days, the village's net intake was 4,503-6,007, and its outflow to the caravan was 3,020-5,376, which is 10 to 20
  times the baseline's 288 in 90 days (proportionally about 2.5 to 4.5 times per day).
- Interpretation only: if the traders' settlement coins were the only outside source (they are not exactly: newcomers' purses are
  included), the village's net intake of 4.5k-6.0k in a year, about the baseline's 90-day figure, would mean the one-way drain slowed sharply after
  the first quarter and the village is buying back. That cannot be confirmed without the settlement coin lines.
- Whether the drain "continued, levelled off or reversed", whether the five settlements declined, and any circulation failure for
  REG-CIRC-D1: **not established by this evidence.** Verdict for REG-EVAL-01 and REG-CIRC-D1: needs the artifact `sim.json`
  (`regions` per sample). I report no circulation failure and no circulation success.
- SET-D (settlement business openings and closings): not logged in the summary; `sim.json` may carry it per sample.
- The village side shows no settlement-related ledger fault: `coin_sources_mismatch` 0 and `holders_mismatch` 0, and no FATAL
  (which includes the settlements' books, `regions.audit`). The end-of-run result is that the settlements' coin, goods and people books balanced at every checkpoint
  of each run (a FATAL would have stopped the run otherwise).

## 6. Multi-generation (SET-D, B18-DP-05): facts only

The owner's rule: a 365-day run is not multi-generation verification. Facts from the logs:
- The approved calendar is 8 days a year (from the regional investigation), so 365 days is about 45 game years.
- Villagers: 104 -> 397 / 310 / 329 / 338 alive. Old-age deaths 91 / 86 / 96 / 73. Elders alive 32 / 23 / 14 / 23; children alive
  130 / 119 / 132 / 148. The births counter 487 / 453 / 520 / 445 (includes newcomers, section 2).
- Households: counter 28 / 29 / 26 / 31 (start 25). Building: houses built 3 / 3 / 1 / 3; sites started 4 / 4 / 2 / 3, finished 3 / 3 /
  2 / 3, none given up; `households_split` 3 / 4 / 1 / 4; lofts started 0 / 0 / 1 / 0; orphans taken in and unplaced 0. About 12-14 people per household
  counted; living households are not logged.
- Settlements: no data (no births, deaths, household or business lines in the logs).
- Not verified here: that the villagers' descendants hold jobs, own households or marry; that the settlements age. Those need the
  per-checkpoint `growth` lines and `sim.json`.

## 7. Summary

**Defects (broken ledger, FATAL, script error): none found.** All four runs reached day 365, exit 0, 0 script errors, currency leak 0,
item leaks none, coin-source and holder mismatches 0, no FATAL.

**Possible defects: need root-cause check**
1. Firewood counter inflated by ended households (seed 4 shows `no_firewood_nights` 4,465): the harness sums `world.gd`
   `for hh in households`, which includes ended households; the real number of cold households is lower by an amount not in the logs.
2. Chapel fund holds 68-85% of all coins (seeds 1-4: 7,375 / 5,099 / 7,119 / 7,466) while villagers hold about 2-3 coins per head, the manor
   treasury is 0-4, and seed 2 shows 348 missed meals for lack of money. Check whether the church-first relief reaches those households, and
   what happens to the manor's wage fund (it feeds manor-hand openings).
3. Low confidence: unemployment 122-188 adults (73-80%) vs Build 17's 6-30; employed 43-48 vs about 74-80 then. Structural cause found in
   code (fixed places, empty treasury, no new fields or trades, coming-of-age adults start jobless). Whether the lost places are the manor
   hand places needs the Build 17 and Build 18 job counts at the same day.

**Notable outcomes (WDR-022: recorded, not defects)**
- No starvation in any seed; mean hunger about 70-71; food days 21-37 (Build 17: 55-204); missed meals for no money far fewer than Build 17.
- Population 3.0-3.8 times its start in a year (397 / 310 / 329 / 338), mostly children and working-age adults; 91 / 86 / 96 / 73 old-age deaths.
- Jobs are the same everywhere: 12 farmers, 6 merchants, 2 smiths, 2 carpenters; only 43-48 of 167-235 adults hold a job.
- Wheat surplus: stock 15.9k-24.7k from 748; price 2.
- Chickens extinct in seeds 2 and 3 (as in Build 17); cows survive everywhere; keeper short of feed or coins on 2-39 occasions.
- 20-26 mine seams worked out; 10-15 tools broke.
- The village took net 4.5k-6.0k coins from outside over the year and spent 3.0k-5.4k with the caravan.

**Not established (evidence blocked):** the day 10/30/100/200 checkpoints (including the required 100-day read), the five
settlements' coins and populations over time, the drain trend vs the 9,249 -> 4,610 baseline, SET-D openings/closings, any
circulation failure (REG-CIRC-D1), and generation detail. These need `sim.json` / `sim.log` from the four artifacts of run 39874405723.

Source files used: the four job logs (saved, parsed copies in `/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad/lr365/`),
`game/tests/economy_sim.gd`, `game/scripts/core/npc_brain.gd` (`seek_work`, `job_market`), `life.gd`, `chapel.gd`, `world.gd`,
`game/data/balance.json`, `docs/build17/MIN_G_LONG_RUNS.md`, `docs/investigations/2026-10-23_regional_economy.md` and the 90-day baseline log.
