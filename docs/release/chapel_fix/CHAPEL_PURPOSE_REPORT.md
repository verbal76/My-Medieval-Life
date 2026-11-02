# Chapel economic purpose: report (2026-11-02)

Branch `wip/b25-chapel-purpose`, from `91cf244` (the Build 25 source). Owner directive
`docs/directives/2026-11-02_chapel_economic_purpose_correction.md`; register CHAPEL-PURPOSE, CHAPEL-LENDING (proposal only),
B25-CHAPEL-FOOD-Q (answered by the directive). Worker report for the lead; the register is not edited here.

## 1. What changed

### Food (directive section 1)

| Rule | Before (`91cf244`) | After |
|---|---|---|
| What the store keeps | `food_reserve`: recent relief for 14 days | Only an emergency reserve: recent emergency relief for `food_reserve_days` (7, until the next service). No food for clergy (paid wages; they eat at home), no livestock (none), seed is not food (never given). |
| Ordinary eligibility | Under `goods_keep_days` (6) days of food | Under `alms_line_days` (14), the owner's hardship line, the same line the coin alms use. The wealthy (`alms_wealth_lines`) excluded as before. |
| Emergency path | Only when a member walked to the chapel and asked (under 2 days) | `relief_round`, every dawn and every 16:00 (before the coin alms), and whenever someone comes to the chapel: the chapel finds every household under `relief_trigger_days` (2), or with a meal missed for want of food in the last `missed_meal_days` (1) and under `relief_fill_days` (3). It uses the whole store, the reserve included, then buys with the fund. |
| Priority | First household to ask | Stage 1: everyone to one day of food, missed meals first, then children or elders, then fewest days. Stage 2: fewest days first, toward 3 days. Then buying, the same two stages. |
| Fairness (alms) | Poorest first, each to its full shortfall | A portion at a time (a pot's grain or one unit) to the household with the fewest days, so a small surplus reaches many households. |
| Order of food | Grain first | Fastest-spoiling first (`decay.spoil` rates): the store records no unit ages, so the food nearest to spoiling is the shortest-keeping; grain last. |
| Transfer | Store to pantry at once, wherever the household was (relief: the asker was at the chapel, the food appeared at home; food alms: no one moved) | A parcel, still the chapel's, lies at the chapel's door (or at the seller's when bought). The preacher, the church assistant or a volunteer carries it (most urgent first, `manor_jobs.haul_max` 10 units a trip), or a member who comes to the chapel takes it home. A carrier who gives up sets it down where they stand. Parcels spoil, are counted in the census, and are saved. |
| Manor relief | Saw the pantry only | Counts chapel parcels made today or yesterday as on their way (no double relief; an older stuck parcel no longer holds the manor back). |
| Wheat offerings | Above 6 days of the household's food | Above 14 days: a household inside the hardship line has no food to spare (otherwise alms food would be offered back). |

The existing instant transfer was judged not to meet "no teleporting", so it was replaced rather than justified. The
manor's own instant delivery for a household under one day of food (`ManorWork.deliver_now`) is the manor's approved rule
and was not touched.

### Money (section 2): the reserve audit

`operating_reserve` = clergy wages x `operating_reserve_days` (5 x 14 = 70 coins) + wages owed + mean weekly relief and
seed spending (last 4 weeks) x 14/7.

| Legitimate need (directive) | In the reserve | Finding |
|---|---|---|
| Wages and owed wages | 70 coins + owed | Two weeks of wages; the fund is refilled weekly, so one week plus one lean service. Owed wages are non-zero only when the fund could not pay, so they never hold back surplus. Modest. |
| Supplies and plot operations | Seed spending, in the recent-spending term | Legitimate. |
| Repairs | None | The chapel has no repair or wear cost in the game; nothing to keep. |
| Modest reserve | The wage term | Measured 70 coins in normal times (10-day runs: fund 55 before, 3 after). |
| Approved projects | None | No chapel project exists; nothing speculative is kept. |
| Relief food buying | Recent spending term | This is the emergency programme; it rises in a famine (383 coins at day 30-40 of the yield-0.5 run while the fund itself was 0: everything had gone on relief food). It holds back coin alms in favour of buying food, which the directive puts first. |

Conclusion: the reserve holds nothing beyond legitimate needs. **No change to the coin reserve.** Coin alms stay as
X20-CHAPEL-FIX set them (14-day line, wealthy excluded). Emergency relief now runs before the alms on the service day.
Donations were not changed; collections were not found to impoverish households (only coins above the OD-19 reserve and
`keep_coins` are ever given). The one giving change is the wheat line above.

### Lending (section 4)

Design only: `docs/expansion20/CHAPEL_LENDING_PROPOSAL.md` (existing systems, what is missing, nine owner questions).

### Instrumentation (section 6)

Read only. The economy_sim `CHAPEL` line has a `cycle` block: in (offered coins and wheat, harvest, sown), use (wages,
relief buying, seed; `ops_food_used` 0 by design), out (emergency and alms food set aside, delivered, fetched, carry trips,
dropped loads, returned, spoiled, coin alms), held (store, food reserve, fund, coin reserve, parcels), people (asked,
emergency found and given, alms eligible and given, households reached, unhelped by reason), starvation (deaths, eligible,
eligible while the chapel had at least a day of the household's food or any coins, and each death's record). Stats are
counters only; `on_starved` reads plain values (no price lookup, which would fill the hour's price cache) and the test
checks the world and RNG are unchanged by it.

## 2. Measurements

### 10-day fingerprint, seed 1 (`--days 10 --seed 1 --every 5`)

| Commit | Fingerprint |
|---|---|
| `91cf244` (before) | `b01fbf44fd1dc38760a9aebc15fddf5c` (the same as the chapel-food worker's branch figure) |
| `2745be7` (first version) | `fdbdde28b18de622de0d250406537392` |
| final (`starvation fix`) | `fdbdde28b18de622de0d250406537392` (unchanged: the odd-grain fix does not arise in 10 days; two runs gave the same value, a determinism check) |

The change is expected: the emergency round runs from the first dawn, so food reaches households that had not asked. Day
10, before vs `2745be7`:

| | Before | After |
|---|---|---|
| Emergency or asked-for relief | 9,201 points (30 asks, 28 relieved) | 24,600 points set aside for 20 households (54 household-rounds), 23,300 delivered in 59 deliveries (45 carrying trips, 14 fetched), 0 left in parcels |
| Food alms | 4,800 points to 5 households | 0 (the emergency round left no surplus; 22 household-weeks under the line, reason `alms_reserve`) |
| Store at day 10 | 3,620 points | 0 |
| Fund / reserve | 55 / 70 | 3 / 70 |
| Coin alms | 72 | 81 |
| Starved | 0 | 0 |

(Points delivered are measured by the store reckoning, where an odd grain counts raw (20) rather than cooked (120); the
gap between set aside and delivered is that valuation, not a loss: parcels were empty at day 10 and the census balanced.)

### Starvation investigation (section 5)

Seed 1, `--market --set shared_manor_farming=1 --set seasonal_village_farming=1`, local:

| Run | Before (`91cf244` + a read-only death print) | After |
|---|---|---|
| yield 1.0, 90 days planned | stopped at day 40 (the session's background time limit): 0 starved | stopped by me at day 20 when no starvation had appeared, to run a harsher stress: 0 starved |
| yield 0.5, 60 days planned | `FATAL day 20: currency leak -2` (`coin_sources_mismatch` -2, `holders_mismatch` 0): 0 starved by day 20 | `FATAL day 40: currency leak -10` (`coin_sources_mismatch` -10, `holders_mismatch` 0): 3 starved, all on day 34 |

Both FATAL stops have the `coin_sources` signature the `wip/b25-leak2` worker is fixing (the unchanged code reproduces it
at day 20). Holders balance in both, and the chapel moves coins only between purses and its fund, so the chapel is not the
cause; reported to the lead, not investigated here. Yield 1.0 produced no starvation in the days reached; yield 0.5 is a
diagnostic stress test only.

The three deaths (after, yield 0.5, day 34, a village-wide famine: granary empty, treasury 24, 73 villagers had left, 2,308
meals missed for lack of food on sale):

| Death | Household position | Chapel position | Qualified | Asked / offered | Delivery | What prevented help |
|---|---|---|---|---|---|---|
| npc 77, elder, 01:42 | hh 17 (3 members): 0 food, 91 coins | 20 points (one odd grain), 0 coins | Yes, emergency (0.0 days, missing meals) | Asked day 19; food set aside day 30 | Delivered day 30; nothing pending | No supply: fund spent (`fund_spent`, day 33), store empty; nothing on sale for its own coins |
| npc 76, child, 04:06 | hh 17 (2 left): same | same | Yes | same | same | same |
| npc 1000071, adult, 07:42 | hh 29 (4): 0 food, 15 coins | same | Yes (0.0 days) | Asked day 34; set aside day 30 | Delivered day 30 | same |

No death occurred while the chapel held usable food or money: the store held a single odd grain (20 points, under a day
for anyone) and the fund was empty. That grain had been held back by a defect found here: the emergency round compared
each portion with the store's own valuation, where a lone grain is worth only its raw food, so a last odd grain was never
given. **Fixed** (the emergency round has no point limit; it stops when the store is empty). The "had means" counter now
requires a day of the household's food or any coins, so a trace does not count. Over 40 days the chapel set aside 36,840
points for 33 households (109 household-rounds), bought food with 726 coins, made 152 carrying trips and 24 fetches; 3,155
round-assessments found a household still under the trigger with the fund spent, 926 with nothing on sale and 853 with
the chapel empty. WDR-022: these are genuine shortages, not hidden rescue failures.

## 3. Tests

| Suite | Result |
|---|---|
| `chapel_test` | 173 checks, 0 failures (on `2745be7` and on the final commit). New: `test_food_alms` (14-day line, reserve, parcels not pantry, wealthy excluded, conservation, save and old save), `test_fair_share`, `test_oldest_first`, `test_emergency` (missing meals first, proactive, reserve usable, unhelped reasons, emergency carried before alms, emergency before coin alms), `test_transfer` (carrying plan, load cap, pantry only on arrival, dropped load, fetch on asking, manor no double relief, census), `test_relief_bought`, `test_reserve_audit` (modest reserve; the death record changes nothing). |
| `conservation_test` | 8 / 0 |
| `net_econ_integrity_test` | 126 / 0 |
| `migration_test` | 109 / 0 |
| `save_transfer_test` | 21 / 0 |
| `elder_provision_test` | 11 / 0 |
| `wiki_test` | all passed |
| `run_tests` | 3,602 checks, 0 failures (on `c5be409`) |
| `tools/check_interactions.py` | 0 problems (INT-226, INT-674 revised; INT-675 new) |

## 4. Final commit figures

After the odd-grain fix: `chapel_test` 173 checks, 0 failures; 10-day seed 1 fingerprint `fdbdde28b18de622de0d250406537392`. The
other suites and `run_tests` ran on `c5be409`; the fix changes only `relief_round`'s point limit and a diagnostic counter, so
they were not rerun (MSW-01).

## 5. Provisional values (agent proposals)

`food_reserve_days` 7, `missed_meal_days` 1; the load per trip reuses `manor_jobs.haul_max` (10); `goods_keep_days` was
removed (its two uses now read `alms_line_days`).

## 6. Not verified

- No year-long or multi-seed run; no run reached day 60 (both stress runs stopped on the coin_sources FATAL, the yield-1.0
  pair was stopped early).
- The yield-0.5 "before" run ended at day 20, so there is no before figure for days 20-40.
- Whether clergy and volunteers keep up with carrying in a large village in a long famine (they did in these runs: no
  parcel left pending at any checkpoint).
- Effect on farmers' grain sales and on the market with `--market` over a year.
- No device check.
