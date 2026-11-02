# Economic investigation: the zero-business problem, unemployment and ore (2026-11-02)

Owner directive: `docs/directives/2026-11-02_overnight_autonomous_development_directive.md` (on `wip/requirements-control`),
sections 4, 5 and 6. Branch `wip/b25-econ-funnel` from `3c7e45b` (Build 25 source, owner B25-BIZ-TENANT-Q Option B
included), `wip/expansion20` merged in at `6603daf`. Developer reference; nothing player-facing changed (no wiki page
touched). Principles kept: WDR-022 (a village may fail, no hidden rescue), conservation, determinism, SIM-01/02, MSW-01.

## 1. Evidence

| Source | Commit | Seeds and length | Use |
|---|---|---|---|
| Actions run 41362329381 (long-sims, normal settings) | `908a17e` | seeds 1 and 2, 365 days, every 30 | year-long jobs (ECON10), BIZ gates, ore left, ledger flows, the neighbours' tills |
| Local run `run120` (this branch, new FUNNEL/JOBS/ORE lines) | `006ca8f` game code = `3c7e45b` | seed 1, 120 days, every 30 | the funnel stage by stage, who is without work, ore and the neighbours' supply |
| Local 10-day runs | `50497cf`, `006ca8f`, `50cc561` | seed 1, 10 days, every 5 | neutrality proofs; day 1-10 market readings |

The 120-day run kept every ledger (currency leak 0, item leaks 0 at every checkpoint, no script error), fingerprint
`71481cb480db38d8c3e8dd13f5bc7765`, 5,017 s (41.8 s a game day). Its last checkpoint is before the year runs' rise in
unemployment (after day 150), so the year's composition of the jobless needs the Actions run in section 8.

## 2. Diagnostics added (read only) and the neutrality proof

- `Ventures._consider` (game code; counts only): `venture_looks` (a living adult of a founding trade on their weekly
  morning), `venture_refused_<stage>` at the stage `Ventures.refusal` stopped (`skill`, `experience`, `keeps_one`,
  `household_ended|household_venture|household_building|household_housing_goal`, `no_home`, `no_work`, `bench_room`,
  `means_unknown`, `money_working`, `no_ground`, `money_start`, `trade_setting_up`), `venture_option_<build|buy|reopen|expand>`,
  `ventures_declined`, `ventures_found_failed`. The stage key is `Ventures.last_refusal`, written by `refusal`, not saved,
  read by nothing that decides. `w.stat` draws no random number and changes no order.
- `economy_sim.gd`: `CONFIG` at the start (which decision systems are on); at each checkpoint `FUNNEL` (the 20 measures
  below; every founding-trade adult's first failing stage and every stage judged on its own, repeating refusal's stages
  without its survey of an unsurveyed house and without `offers()`' clean-up), `JOBS` (jobs; who the adults without a job
  are; job changes by direction and reason, parsed from the village notes; fruitless searches; apprentices; retirements;
  vacancies; migrants), `ORE` (each ore's deposits, found, mined, used, imported, exported, held; tools and bars; mining
  people, places and prospecting; each neighbour trader's till, spendable coins and stock, and the quarry's stock and
  reserves). `.github/workflows/long-sims.yml` prints the four new lines.
- Neutrality: seed 1, 10 days, `--every 5`, the three sample fingerprints (`8f06b0d2…`, `a4c8fc94…`,
  `67b6c604d4f2f83ee99132517f961630`) identical to a temporary worktree of `3c7e45b`, after each instrumentation commit and
  after the merge; every other output line identical apart from timings.
- `business_founding_test.gd` `test_funnel_counts` (new).

## 3. Were the decision systems on? Yes

`CONFIG` of the default `economy_sim` run (no switches, as long-sims runs with empty `sim_args`): judgment attached,
`business_found` on (`JudgmentLive.on` true, `decision.integration.business_found` true), `job_choice` on,
`aspiration.enabled` true, `aspiration.apply` factors/court/proposal off (the shipped Build 25 career ambition only), no
override, Living Economy off. The career ambition worked (63 ambition looks, 3 moves by day 120). The founding decision
(`decides`) was never reached because nobody passed eligibility: it is not a switched-off system.

## 4. The business-founding funnel (section 4)

### 4.1 Where potential founders are eliminated

Founding-trade adults (smith, carpenter, tanner, cook), seed 1, local run. "Pass" counts judge each stage on its own;
"first failing" is refusal's order.

| Day | In trade | Skill ≥4 | Experience ≥20 d | Household free | Has home | Owns home | **Opening (work and no room)** | Spare > working capital | Spare ≥ start + working | First failing stage |
|---|---|---|---|---|---|---|---|---|---|---|
| 30 | 10 | 9 | 7 | 10 | 10 | 7 | **0** | 2 | 0 | no_work 6, experience 3, skill 1 |
| 60 | 10 | 8 | 8 | 10 | 10 | 7 | **0** | 2 | 0 | no_work 7, skill 2, experience 1 |
| 90 | 10 | 8 | 9 | 10 | 10 | 7 | **0** | 0 | 0 | no_work 8, skill 2 |
| 120 | 8 | 5 | 5 | 7 | 8 | 4 | **0** | 1 | 1 | no_work 4, skill 3, experience 1 |

The game's own counts of the weekly looks to day 120: 184 looks (172 by living adults; the 12 `trade` refusals were dead
villagers' records, now excluded, commit `d5e32ef`): refused at `no_work` 106, `experience` 36, `skill` 29,
`bench_room` 1; considered 0, founded 0.

The trade's demand reading (`NPCBrain.skilled_place`: the share of a 660-minute working day each worker spends at the
trade's stations; `work` needs 0.35, an opening also needs no free bench time):

| Day | Smith | Carpenter | Cook | Tanner | Room (free bench time) |
|---|---|---|---|---|---|
| 1 | 0.535 | 0.295 | 0.406 | 0.096 | yes, all four |
| 5 | 0.386 (a place opened; a third smith was hired) | 0.248 | 0.267 | 0.062 | yes |
| 30 | 0.148 | 0.185 | 0.201 | 0.038 | yes |
| 60 | 0.022 | 0.035 | 0.067 | 0.019 | yes |
| 90 | 0.052 | 0.051 | 0.080 | 0.027 | yes |
| 120 | 0.090 | 0.069 | 0.075 | 0.019 | yes |

**Finding.** The binding stage is economic opportunity. From the second week the founding trades' own workers are idle
at the manor's stations for most of the day (2-20 % busy), so there is neither work for another hand nor a full
workshop. A new workshop of the trade would add benches nobody needs. The other gates matter only behind it:
experience (the provisional `min_trade_days` 20 is above the starting experience a tanner can have, since tanning's cap is 18
days; a tanner reaches it only by working), capital (at most 2 of 8-10 households can spare more than the 10 days' working
capital, at most 1 can also pay the start of 89-111 coins) and, by the year's end, housing goals (22 crowded households in seed 1).

### 4.2 The year runs' BIZ line, re-read

The BIZ line's gates are sequential: `owns_house 0` at day 365 means that nobody passed the earlier gates. It does not mean
that few villagers own homes. In the 120-day run 22-23 of 25-26 households own their homes and 3 rent; after Option B,
renting no longer blocks founding.

### 4.3 The directive's six outcomes

| Outcome | Seen? | Evidence |
|---|---|---|
| Nobody was eligible | **Yes: the whole result** | 0 of 8-10 pass "opening" at every checkpoint; 0 considered in 172 looks |
| Eligible villagers declined | No (none eligible) | `ventures_declined` 0; the decision is unit-tested (`test_decision`) |
| Wanted to proceed but lacked resources | No (none reached it); capital would bind next | spare > working 0-2 of 8-10 |
| Construction failed | No | no site marked out |
| Opened but could not operate | No | none opened |
| Operated but closed | No | none opened |

### 4.4 The 20 measures (day 120 unless stated; FUNNEL line)

1. Adults 72 (job 62, none 10), elders 11, children 37 (alive 120).
2. Founding trades: smith 1, carpenter 2, tanner 1, cook 4 (+ tavernkeeper 2, merchant 6). Year runs: 8-9 all year.
3. Skill in the trade's own skill: cook levels 3,4,6,8; carpenters 6,8; the smith and the tanner are level-0 apprentices
   (the masters retired). Outside the trade with level ≥4: 2 carpenters in tanning, 1 sage and 2 tavernkeepers in cooking.
4. Experience ≥ 20 working days: 5 of 8 (cooks count days in the job).
5. Housing: 26 households, all housed, 3 with a housing goal, none building.
6. Ownership: 23 own, 3 rent.
7. Commercial land: ground for a smithy, carpentry and bakehouse found near the manor and near every candidate's house.
8. Construction feasible: yes (ground, the house-first rule, materials held in the village).
9. Household capital: candidates' spare after keep and tools -242 to 219 coins.
10. Start (ground 60 + a quarter of the materials): smithy 111, carpentry 90, bakehouse 90; whole cost 180-264.
11. Working capital (10 days of household costs): 56-128 coins.
12. Materials held: logs 720, planks 171, blocks 24 (a bakehouse or a smithy needs 30), iron bars 24.
13. Demand: table 4.1; no trade had `work` after day 5.
14. Capacity: smith 2 stations, carpenter 2, cook 3, tanner 1 (the workbench, shared); 19-198 minutes worked a day against 660-1980.
15. Workshops for sale: none (no villager workshop exists).
16. Selling: mean daily earnings smith 0.0 (the apprentice), carpenter 14.0, cook 4.6, tanner 0.0.
17. Judgment and ambition: on (section 3); 63 ambition looks, 3 moves.
18. Founding attempts: 0.
19. Rejections: section 4.1.
20. Construction, transfers, openings, hiring, operation: 0 (skilled hires through the labour market: 3, all in the first week).

## 5. Professions and unemployment (section 5)

**Who is counted.** economy_sim's "unemployed" is an adult (role `adult`, ages 16-55; the reeve and the sage stay adults
past 55) with no job. Children under 16, elders (55 and over, retired) and bandits are not counted. Day 120: 10 jobless,
**all young people who came of age in the run and never had a job** (26 came of age), 0 sick or hurt, median coins 0, 5 of
them in a household with children and another earner. The game has no household-work or carer role, so such an adult
counts as without a job. The count is accurate; "available labour" is a slight overstatement only in that sense.

**Why the founding trades stay at 8-9.** They stay at the starting strength (`Population.JOBS`: smith 2, carpenter 2,
tanner 2, cook 3). Succession refills a post to that strength after a death, retirement or departure (8 apprenticeships by
day 120). A trade grows above it only through `skilled_place` (room, work and earnings). Its work collapsed after the
first week, so only 3 skilled hires happened, all by day 5 (2 untrained, 2 retrained). Newcomers get vacancies and the floor jobs only
(Migration). The career ambition moved 3 people. **Classification: legitimate outcome** of the approved rules
(B25-EMPLOY-D3: no headcount quota, no artificial vacancies).

**Why unemployment grows (year runs: 4 → 141 seed 1, 3 → 112 seed 2).** Population roughly triples (104 → 308-356) while the places stay
bounded by what the village has. Farmers: 12 (6 fields × 2), constant all year. Woodcutters: grown trees / 30. Hunters:
takeable game / 6. Miners: reachable ore and quarry stone / 40, falling with depletion. Manor hands: the treasury's spare
over 20 days' wages; the treasury sits at 3-100 coins for most of the second half, and manor hands fall from 7 to 1 in seed 1 (seed 2 keeps 10-14).
Service and clergy: one each. The skilled trades: demand. In the year runs miner (1-10) and woodcutter (1-5) places
stayed open while the jobless rose. A job with a tool is open to a seeker only if they own the tool or can pay for one
(`_job_options`), and the jobless have 0 coins (they never earned). The manor's tool support (OD-16, `_support_trades`)
serves only workers already in a trade, and its treasury is empty. 627 morning searches found nothing by day 120.
**Classification:** the growth is a legitimate outcome; whether a coinless young adult may get a first tool is a
**policy question (P2)**.

**Apprentices advancing:** yes, slowly. The apprentices of day 120 are level 0. Experience only accrues from work at a
station (1 day per 480 minutes), so with the stations 2-9 % busy an apprentice gains about 0.1-0.6 experience days a
day. **Lack of work prevents experience accumulation:** yes (outcome).

**Retirement, death and succession:** 10 retirements and 26 comings of age by day 120. Succession passes the master's
*tools* (`_late_masters_tool`). It does not pass the trade's *stock*, and elders and jobless adults never sell. At day 120,
retired villagers held 68 iron ore, 47 coal, 24 iron bars, 8 pickaxes and 7 axes. A cook, formerly a merchant, held 20
iron ore and 20 coal. The village's only smith, an apprentice, held nothing and earned 0. **Policy question (P3).**

**Permanently trapped:** within 120 days, all 10 jobless have been without a job since coming of age, with 0 coins and no
tool-free place open. Whether this lasts all year is for the Actions run (JOBS `days_without`, `never_had_job`). Note that
`days_without` counts from day 0 for someone who never held a job.

## 6. Ore (section 6)

| | Iron ore | Coal | Copper ore | Gold ore | Tin ore | Stone |
|---|---|---|---|---|---|---|
| Village deposits at start | 480 | 350 | 120 | 8 | 0 | 320 (+ quarry) |
| Found by trial pits to day 120 (seed 1) | 168 | 70 | 30 | 0 | 48 | 180 |
| Mined to day 120 | 648 | 420 | 150 | 8 | 48 | 319 |
| Used (smelted) | 512 | 335 | 70 | 8 | 6 | 146 |
| Imported / exported | 0 / 22 | 0 / 20 | 0 / 15 | 0 / 0 | 14 / 4 | 0 / 44 |
| Deposits left day 30 / 60 / 120 | 0 / 65 / 0 | 48 / 9 / 0 | 0 / 30 / 0 | 0 | — / 2 / 0 | 296 / 296 / 287 |

- **Extraction outpaces use.** About 16 iron ore a day was mined in the first month against about 12 smelted, so stock
  built up (130-150 held) and the original iron seams ran out by day 30 (year runs: seed 2 by day 60, seed 1 by day 120).
  Miners: 8 → 11 → 9; places open 3-5. Prospecting: 24 samples, 17 trial pits (13 misses), 9 seams found, all by day 60.
  Nothing after that, as the manor's surveys and trials are paid from a near-empty treasury. Mining level 2 → 1.
- **Consumption by industry:** the smiths smelt (iron bars made 372, used 204; seed 2's year: 315 made, 131 exported to
  the caravan). The smiths' own work fell to 2-9 % of the day after the first month. **The smiths were short of buyers, not of ore.**
- **Imports:** a smith buys up to `caravan_import_stock` once the village's seams of that ore are ≤ 10 (`_caravan_imports`),
  only from a trader on the road who holds some. The only ore-producing neighbour is Garton (quarry 2.5 iron a day,
  reserves 1,500). Its quarry stock rose from 63 to 175 by day 60, but its trader's till sat at its floor (year runs:
  trader 0 coins from about day 30 to day 300 in seed 1). So it could not buy its own quarry's ore (`_trader_collects` pays
  from the till above the floor) and carried none on the road. The village imported **0 iron ore in 120 days** (seed 2's
  year: 2 iron ore, 17 coal).
- **Rules:** finite deposits with no refill (WDR-013), discovery of finite bodies by trial pits (MIN-C/MIN-D), imports
  only from real stocks (ECON-P1.3). OD-01 (owner, 2026-10-21) rejected demand-driven mining (P1.1), a stone reserve
  (P1.2) and a special distant quarry (P1.5). The depletion follows these rules; nothing regenerates and nothing appears
  from nowhere. **Classification: depletion is an intended consequence (outcome), and the rules operate as written.** The
  regional supply stall is a **policy and evidence question (P4)**: an insolvent trader is a legitimate outcome, but a
  neighbour whose only channel has no coins never sells its ore. The year run, with trader till and stock now in ORE, will
  show whether the stall persists or clears.

## 7. Defects found and fixed

- None found in the game's rules for founding, employment or ore: each traced path does what its approved rule says.
- Diagnostic defect in this branch's own counting (commit `50497cf`): a dead villager's record (job kept) was counted as a
  look refused at `trade`. Fixed in `d5e32ef` (only living adults counted); `test_funnel_counts`.
- Harness reading: the BIZ line's sequential gates were read as "few own their homes" (section 4.2); FUNNEL now gives
  independent counts.

## 8. Open questions for the owner (options and recommendations)

**P1. Demand is what limits businesses.** The founding rule needs the trade's own benches to be full and busy. From the
second week they are 2-20 % used.
- A. Keep (recommended): a workshop with idle benches beside it adds capacity nobody buys. Work on demand instead (P2-P4,
  which put goods, tools and people back into circulation).
- B. Let a skilled villager weigh independence: found when their own income at the manor's benches is below their
  household's costs and their skill is high, even with free bench time.
- C. Lower the provisional `skilled_places.busy_share` (0.35) for founding only. Not recommended: the measured share is
  far below any reasonable threshold.

**P2. A coinless young adult cannot take a place that needs a tool.**
- A. Keep.
- B. The household may buy a member's first work tool from its purse, as relatives already help build a home (a family
  transfer, no coin made). Recommended.
- C. The manor advances a tool to an applicant for an open place (OD-16 extended; treasury-limited).
- D. Tool rental (LE05) outside the Living Economy.

**P3. A retired or departed tradesman's stock is stranded.**
- A. Keep.
- B. A villager without a trade (an elder, or an adult between jobs) sells goods that have an outlet through the
  existing sell rule (`_plan_sell_all`, at market prices). Recommended.
- C. On retirement the trade's stock passes to the successor as the tools already do (B8-016 extended).

**P4. The ore neighbour's trader has no working coins, so the village cannot import ore.**
- A. Keep as the finite regional market's outcome.
- B. The trader takes its settlement's ore on consignment and pays the quarry when it sells.
- C. Village smiths buy from a neighbour's quarry business directly.
- Recommendation: decide after the year run with the new ORE line; lean to B.

**P5. Places do not grow with population** (fields, trees, game, ore and the treasury are fixed or finite). Recorded as an
outcome. Whether land or fields should expand (households clearing or buying fields) is a design decision for the owner;
no change is recommended from this evidence.

The provisional `ventures.min_trade_days` 20 is above tanning's starting-experience cap of 18. It is an agent value that
does not bind today (demand does), so it is left as it is.

## 9. Recommended Actions run

`.github/workflows/long-sims.yml` on branch `wip/b25-econ-funnel`: seeds `1,2`, days `365`, every `30`, set empty,
variants empty, sim_args empty (the shipped switches), record false. It prints CONFIG, FUNNEL, JOBS and ORE with BIZ and
CAPMS. It answers the year-long composition of the jobless (section 5), whether the trader stall persists (P4) and the
funnel after day 150. Run 41362329381 took 3.8 h (seed 1) and 4.4 h (seed 2) on `908a17e`, within the job's 330-minute limit; a little more for the extra lines.

## 10. Not verified

- The year-long funnel, the jobless composition after day 150 and the regional trader's till and stock over a year (local
  run only to day 120, seed 1).
- Seed 2 locally; any `--market` or economy-on configuration.
- The founding decision in a live run (never reached); it is covered by the unit tests only.

## Wiki and Documentation

No player-facing behaviour changed, so no wiki page was created or updated (`wiki_test` not needed). Technical references:
this document; `docs/expansion20/BUSINESS_FOUNDING.md` section 2 names the new diagnostic counts.
