# CHAPEL-R2 spending audit (root cause)

Code 9a86f5c (`wip/build18`), probe-only edits in worktree `rcachapel` (nothing committed, pushed or written to `docs/requirements/`).
Authority: `docs/directives/2026-10-23_dp17_chapel_r2_longrun.md` (CHAPEL-R2: no economic value change approved; correct verified defects only; no new redistribution, spending or economic rules). WDR-022 applies.

## Evidence used
- Probe runs, 150 days, seeds 1 and 2 (`xdg_rca/run1.log`/`out1.json`, `run2.log`/`out2.json`): a `PROBE` line every 10 days. They reproduce the 365-day run exactly where they overlap (seed 1 day 150: unemployed 36, treasury 115; seed 1 day 100: 26 and 549; seed 2 day 100: 13 and 358; the same as `LONG_RUNS_365.md`).
- Counterfactual `runcf1.log` (30 days) and ONE new run: `MML_NO_OFFER=1` (chapel `coin_share` 0), seed 1, 150 days, `xdg_rca/runcf150.log`/`outcf150.json`. It was needed because the 30-day run could not show whether the treasury and the hands recover over the months that matter.
- Destitute scenario `runsc.log`/`outsc.json` (seed 2): at day 20 all villagers' coins moved to the chapel (2,811) and five households' food removed.
- Seeds 3 and 4 have no probe: only their 365-day report figures exist. Their chapel flows are not in any log (see the table notes).

## Classification

| # | Question | Class | Result |
|---|---|---|---|
| 1 | Clergy wages | **B, works as designed** | Paid in full every day: 50 coins per 10 days (3 + 2 a day), 150 by day 30, 500 by day 100, 750 by day 150, in both seeds. The fund was never empty, so `owed` stayed 0. In the counterfactual (fund 0) owed rose to 50, 70 and then stayed at 70 (5 a day x 14 days: the cap works). Both clergy stayed alive and employed throughout. |
| 2 | Relief food | **B, works as designed** (one design gap to report, no defect) | Fires on `household_food_days < relief_trigger_days (2)`, by a household member asking (`chapel.gd` `plan_ask`, line 267; `ask` 283; `relieve` 306). See below. |
| 3 | Offerings in, spending out | **B** | Inflow far above the designed outflow; nothing is leaking. See the table. |
| 4 | Treasury and unemployment | **B** (cause isolated; not a code defect) | The weekly offerings take the cash the daily tax would have taken. See below. |
| 5 | Firewood counter | **C, counting artefact in principle; not shown to be inflated** | `world.gd:459-463` counts every entry of `households`, ended ones included. Ended households were 0 through day 150, so the counter equalled live households there. |

No class A (verified defect) was found.

## 2. Relief in detail

Trigger (code, not memory):
- `Chapel.plan_ask` (`chapel.gd:267-280`): the household's food days (`NPCBrain.household_food_days`, `npc_brain.gd:3409`: pantry + every member's pack + what the household's cash can buy from food on sale, capped by its market share) must be under `relief_trigger_days` = 2. It is asked once a day per household (`asked`/`booked`), and only if `can_give()` (store has food or the fund has coins).
- It is called from `_plan_evening` (`npc_brain.gd:843`), which a villager reaches before 7:00, after 18:00, or when jobless/an elder. A working member who is hungry and fails `_plan_eat` goes on to work; the household asks that evening. Latency is at most one working day.
- `ask` -> `relieve` fills the pantry toward `relief_fill_days` (3): store wheat first, other food next, then buys with the fund (`_relief_offers`). The manor's 17:00 relief then gives only the rest.

Evidence it fires:
- Seed 1, 150 days: asked 98, relieved 97, 429 wheat from the store, 40,546 food points. Seed 2: asked 46, relieved 44, 166 wheat, 14,945 points.
- Destitute scenario (day 20): five households at 0 food days, every villager at 0 coins, fund 3,216. Chapel asked 2 on the day and 1-2 on each following day, giving 433-853 points a day; the missed-meal count went to 0 from day 21 on (day 20 itself: 746 failed attempts, all before the evening ask; the counter counts attempts every few game minutes, not meals). All 744 logged no-money misses had `fd` = 0.00, so each of those households qualified.
- A household that misses a meal for lack of money with food on sale (`priced` true, no payer) qualifies exactly when its food days are under 2, which is the case whenever its pantry and packs hold no edible food and its cash buys under a unit. A household holding 2+ days of food does not qualify; it has food, and the individual's missed meal is a retry that ends at home.
- `chapel_relief_bought` = 0 in every run: relief never needed to buy, because the store (food offered by wheat-rich households + the plot) covers every request (114,180 food points in the store at day 150 in seed 1; 230k-375k at day 365 in the long runs, against a village need of 19-25k points a day). This is why the fund's coins are never spent on relief: the first stage of the design (donations and crops first) always suffices.

Design source (verbatim):
- `docs/directives/2026-10-23_chapel_clergy_relief.md`: "their donations and their crops are the first form of relief. Villagers can go to the church and ask".
- `docs/directives/2026-10-23_chapel_donations_farm.md`: "All the donations to the chapel should be the first funds that are used to go to food relief".
- `docs/directives/2026-10-23_owner_answers_chapel.md`, the owner's chosen answer: "Priest + alms (Recommended)": a small chapel with a priest villager; offerings keep the priest, and what is left goes as alms to the poorest households; the coins stay in the village".

Fact for the owner (not a defect, so not fixed): the code implements "offerings keep the clergy; relief is food". It has no path that hands the left-over coins to the poorest households (the "alms" leg of the owner's answer), and nothing spends the fund unless the store runs out. The fund therefore only grows. Doing it would be a new spending rule, which CHAPEL-R2 says not to introduce without approval. It needs an owner decision.

## 3. Offerings, wages, relief, seed (150 days; probe deltas summed)

| Seed 1 | day 30 | day 100 | day 150 |
|---|---|---|---|
| Offerings in (coins) | 1,276 | 4,464 | 6,135 |
| Clergy wages out | 150 | 500 | 750 |
| Relief bought with coins | 0 | 0 | 0 |
| Seed bought | 0 | 0 | 0 |
| Fund balance (= in - wages) | 1,126 | 3,964 | 5,385 |
| Wheat offered / wheat relieved | 26 / 137 | 835 / 168 | 2,268 / 429 |
| Manor tax collected (cum.) | 1,402 | 7,148 | 9,162 |
| Manor wages paid (cum.) | 1,546 | 5,862 | 8,054 |

| Seed 2 | day 30 | day 100 | day 150 |
|---|---|---|---|
| Offerings in | 1,085 | 3,424 | 4,334 |
| Clergy wages out | 150 | 500 | 750 |
| Relief bought / seed bought | 0 / 0 | 0 / 0 | 0 / 0 |
| Fund balance | 935 | 2,924 | 3,584 |
| Wheat offered / wheat relieved | 29 / 110 | 1,574 / 114 | 4,002 / 166 |
| Manor tax collected (cum.) | 1,308 | 6,540 | 8,649 |
| Manor wages paid (cum.) | 1,568 | 5,300 | 7,092 |

Per 10 days, offerings run 140-690 coins (seed 1 mean 410, seed 2 mean 290) against wages 50 and relief-purchase 0, so the net into the fund is 90-640 per 10 days; the fund never fell in any period. Check: fund = offerings - wages exactly (seed 1 day 150: 6,135 - 750 = 5,385).

Why the inflow is large: each adult with piety >= 0.3 gives `floor(spare x piety x 0.3)` every 7th day, where spare = purse - OD-19 reserve - 8 (`chapel.gd:offerings`), a repeating tithe on whatever they hold above the reserve. Provisional values: `coin_share` 0.3, `min_piety` 0.3, `keep_coins` 8, `offering_every_days` 7, wages 3/2 (`balance.json` "chapel", all agent proposals marked provisional). Outflow is limited by design to wages (5 a day) plus coins for relief only when the store is empty. Inflow of 290-410 per 10 days against 50 out is the designed rules under the provisional numbers: **B**.

Day 365 (long-run report; wages and purchases are derived, not logged past day 150):

| Seed | Fund at day 365 | Share of world coins | Offerings in (derived: fund + 365 x 5 wages, assuming no purchases as in days 0-150) | Chapel food store (points) |
|---|---|---|---|---|
| 1 | 7,375 | 84.9% | about 9,200 | 230,400 |
| 2 | 5,099 | 68.3% | about 6,900 | 375,300 |
| 3 | 7,119 | 79.6% | about 8,900 | 241,540 |
| 4 | 7,466 | 83.7% | about 9,300 | 286,140 |

## 4. Treasury and unemployment

Cause, from the 150-day counterfactual against run1 (same seed, same code, only `coin_share` = 0):

| Day | Fund (with) | Treasury with / without offerings | Villagers' coins with / without | Tax in per 10 days with / without | Manor hands with / without | Adults / employed / unemployed with | Adults / employed / unemployed without |
|---|---|---|---|---|---|---|---|
| 30 | 1,126 | 36 / 435 | 3,460 / 4,041 | 784 / 1,666 | 0 / 0 | 64 / 61 / 3 | 64 / 61 / 3 |
| 60 | 2,308 | 418 / 1,548 | 3,379 / 4,609 | 883 / 1,672 | 0 / 17 | 72 / 60 / 12 | 78 / 75 / 3 |
| 100 | 3,964 | 549 / 1,747 | 2,717 / 5,067 | 627 / 1,874 | 2 / 22 | 89 / 63 / 26 | 94 / 80 / 14 |
| 150 | 5,385 | 115 / 1,741 | 2,103 / 6,068 | 256 / 1,681 | 0 / 23 | 96 / 60 / 36 | 109 / 81 / 28 |

Cumulative tax to day 150: 9,162 with the offerings, 24,908 without. Manor wages: 8,054 against 21,198. Guards on day 150: 2 against 3 (6 at the start in both; the manor reopens a guard's post only above 10 days of wages).

Mechanism (code):
1. The weekly service takes coins at 16:00 (`chapel.evening`, `chapel.gd:evening`), from individuals' purses above reserve + 8.
2. The reeve taxes at 17:00 (`npc_brain.gd:reeve_day`, 2776-2807): rate x household cash above an exemption of 40 + 20 per member (`balance.json` tax_*), the rate 12% (treasury under 10 days of wages), 6% above, 0 in the tax holiday. The tax base is the same excess cash the chapel's 30% x piety weekly share has already taken, so the tax base shrinks as the fund grows. The coins do not vanish: they sit in the fund. World coins are conserved (the 365 runs: 0 leaks).
3. The treasury pays wages as it receives them (guards, reeve, hands, day labour, relief, repairs). With tax falling from about 1,000 to 256 per 10 days, the treasury falls below the line for hiring: `job_market` manor hands = `(treasury - 10 days of obligations) / (wage x manor_hire_runway_days)`, i.e. 0 below about 460+ coins.
4. Without offerings the treasury holds about 1,500-2,000 and 17-26 manor hands work from day 60.

Unemployment: the chapel is not the whole story. Employment is flat at about 60 jobs in the run with offerings (60 -> 63 -> 60) because jobs are fixed by succession plus openings, while adults grow 60 -> 96. The treasury-linked part is the manor hands (0-2 against 22-23) and guards; the rest of the unemployed (about 36 against 28 without) is population growth with no new places. In the counterfactual unemployed also grow (28 at day 150 with 109 adults) once the hands are full. So the chapel explains most of the loss of employment (employed 60 against 81 at day 150), not all the growth of unemployment.

Verdict: **B**. The offerings and the tax both work as written; the interaction under the provisional `coin_share`, `piety`, tax exemption and tax rates, plus the treasury-gated hiring rule, is what empties the treasury. No code defect. The treasury is not drained by wages of the clergy (50 a 10 days), relief buying (0), or seed (0). Tills and tax-law changes were not needed to explain it.

## 5. Firewood (`no_firewood_nights`)

- The harness reads the game's note "N households had no firewood last night" (`economy_sim.gd` event handler) which `world.gd:459-463` builds from `for hh in households: if not hh.pantry.remove("log"): cold += 1`. `households` includes ended households (`property.gd:448 household_ended` only sets `ended`; the entry stays), so each ended household with an empty pantry adds 1 a night.
- Evidence of size: `cold_live` (live households with no log at the probe) against `allhh`: ended households were 0 at every probe to day 150 in both seeds, so the counter was exact there (about 7-17 cold of 25-27 households). The 365-day counters (3,057 / 3,417 / 3,325 / 4,465, i.e. 8.4 / 9.4 / 9.1 / 12.2 a night) are within the live range seen at day 150 (7-17), so no inflation is visible; whether ended households existed after day 150 is not logged (the `households` counter 26-31 does not say). I can neither confirm nor exclude inflation on days 150-365.
- Class **C (counting artefact in principle)**. Smallest fix, in the counter only: skip households with `ended` true in that loop (or have the harness count households with living members), and log live and ended household counts at each checkpoint. It does not touch simulation behaviour apart from stopping the nightly burn of a log from an ended household's pantry; the escheat sends those stores to the granary at the end of a household, so nothing is lost. Not changed here.
- Separately: about a third of the live households have no log on a typical night, in every probe, with or without offerings. That is the log supply and not the chapel; not examined further.

## Defects and fixes
- Verified defects (class A): none.
- Counter (class C): `no_firewood_nights` can include ended households; fix is a one-line `ended` skip in the counting loop (`world.gd:459-461`) or a live-household count in the harness. Not shown to be inflated to day 150.
- Observations for the owner (no code change):
  1. The fund only grows: relief never buys (the store always suffices), and the owner's "what is left goes as alms to the poorest households" has no coin path. Doing so is a new spending rule (owner decision).
  2. The weekly tithe is the main cause of the empty treasury, the closed manor-hand places and the lost guard posts. The provisional numbers to look at are `coin_share` (0.3), `min_piety` (0.3), `keep_coins` (8), and the tax exemption. No change was made.
  3. A fully employed destitute household asks the church only in the evening (up to a working day of hunger), the same timing as the manor's relief. This is a latency of the design, not a break.
  4. Missed meals are counted per failed attempt, not per meal (746 attempts for 5 households in one day). The seed 2 figure (348 no-money misses) is also attempts. The per-miss household state for the 365-day runs was not logged, so I cannot say what share of those households had 2+ food days.

## Does anything need the 365-day runs repeated?
No. There is no class A defect, so no code changes behaviour. The only possible change (the firewood counter) alters a diagnostic counter, not the simulation.

## Wiki and Documentation
None changed (read-only audit).
