# F015/P99: seed 2 population, 316 against 203 (B25-F015-POP-01)

Read-only investigation, 2026-11-10. Owner directive item 5 (docs/directives/2026-11-10_build25_merge_decisions.md on
wip/requirements-control). No code changed, nothing merged or dispatched.

- Baseline: fbfd6ad, campaign 42788018729.
- Candidate: 3d515d6 (fbfd6ad + 3570832 P99 + 3d515d6 F015), campaign 42832338970.
- Evidence used: the four segment run logs (sim.log, `fr-seed2-segN-run`) and the day-300 states (`fr-seed2-state3`) of both
  runs, the results workbooks of both runs, and the seed-2 and seed-1 results of two earlier campaigns:
  42760291468 (b57261f) and 42734194963 (acc24b2).

## 1. Where the populations part

| day | baseline alive | candidate alive | baseline arrivals (hunger) | candidate arrivals (hunger) |
|---|---|---|---|---|
| 10 | 107 | 111 | 0 | 0 |
| 100 | 134 | 138 | 9 (0) | 8 (0) |
| 150 | 150 | 152 | 21 (11) | 16 (7) |
| 180 | 173 | 153 | 40 (30) | 17 (7) |
| 230 | 202 | 159 | 70 (55) | 30 (17) |
| 300 | 227 | 145 | 72 (55) | 35 (21) |
| 365 | 316 | 203 | 167 (149) | 90 (74) |

The worlds differ from the first days (day 10: 107 and 111 alive, 3 and 2 deaths). The populations stay level until day 150 (150
and 152). They part in two waves: days 150-230 (+29 hunger arrivals in the baseline against +10) and days 300-365 (+94
against +53).

## 2. What makes up the difference

At day 365, from the summary and the run logs (village rows only):

| component | baseline | candidate | difference |
|---|---|---|---|
| arrivals (migration "in"; summary 173 / 93) | 167 | 90 | -77 |
| of which "in:hunger" | 149 | 74 | -75 |
| of which "in:marriage" / "in:work" | 10 / 8 | 8 / 8 | -2 / 0 |
| departures (migration "out") | 44 | 36 | +8 |
| births | 206 | 137 | -69 |
| deaths (old age / starvation) | 119 (84 / 28) | 92 (73 / 14) | +27 |

Net: -77 + 8 - 69 + 27 = -111. The rest is the job-market count against the summary's arrival count.

**Arrivals.** Hunger arrivals account for 75 of the 77 missing arrivals. These come from the rule
`Migration._hunger_in` (game/scripts/core/settlement/migration.gd:839-859). It has two sides:

- Village side: no famine, `w.food_days >= reserve_days` (2), food capacity for the newcomers, and `_can_house` (a home on the
  market or any household that is not a couple). These held in both runs the whole year: village food was 9.8-18.7 days at every
  checkpoint.
- Settlement side: a settlement on the caravan road that day has a household that has been hungry for at least
  `move_patience`, holds fewer coins than a day's food, and has less in its pantry than its need.

So the arrivals were decided on the settlement side, by how many destitute, hungry households the off-map settlements had.
The run logs' `neighbours` line shows this:

- Baseline: Bourton Abbas collapsed. It went from 61 people and 266 coins (day ~150) to 0 people (day ~290), with 56 deaths
  there. Its households came to the village by hunger on days 153 and 169. Wulstead had 3-5 hungry households from day 160,
  and 30 of its people came by hunger on days 167-221 (`regions.moves` in the day-300 save: Wulstead 30, Netherton 16,
  Bourton 9). After day 300, Wulstead went from 103 to 35 people and Garton had 8-12 hungry households.
- Candidate: Bourton declined slowly (60 down to 29-40 people, with about 300 coins left). Wulstead had 0-4 hungry households.
  Hunger arrivals by day 300 were Wulstead 11 and Netherton 10. After day 300, Wulstead fell only to 80 people.

**Births** follow the arrivals. Hunger arrivals are whole settlement households, mostly couples:

- Partnerships at day 300: 45 in the baseline, 33 in the candidate. At day 365: 54 and 40.
- Fertile couples free to have a child ("could"), days 180-365: 3,325 couple-days in the baseline, 2,185 in the candidate.
- Births in days 0-180 were the same: 71 and 73. The whole birth gap comes after the arrivals part.

The birth rule `Life.births` / `_try_birth` (game/scripts/core/life.gd:591-636) reads:

- a mother aged 18-42 with a partner;
- `household_food_days >= birth_min_food_days` (1);
- no child in the last year;
- a 1/16 chance a day.

`household_food_days` is unchanged by F015: the commit only adds comments above it. "low_food" couples were 0 at almost every
checkpoint in both runs. One part is not explained: after day 180 the candidate's births per "could" couple-day are lower,
0.029 against 0.041. This is measured from 10-day snapshots, so it is coarse. No changed code is read by the birth rule.

**Deaths.** There are fewer deaths with fewer people. Starvation was 28 against 14. 15 of the baseline's 28 starvation deaths
came in days 340-365, when its newcomers took village food down to 9.8 days.

## 3. Does F015/P99 reach these rules?

- **F015.** `household_food_held_days` is read only by Homesteads (homesteads.gd:1296, 1418, 1518, 1533) and Wilds (`plan_hunt`
  wilds.gd:173 and the pen slaughter wilds.gd:959), all for homestead claimants. That is 1-4 people on seed 2. The grain
  fallback is in `Homesteads._errand` only. Neither Migration nor Life nor the off-map settlements read the new measure, and
  `household_food_days` (read by the birth rule and by migration.gd:669) is unchanged.
- **P99.** It changes only how `NPCBrain._smith` and `_fetch_for_order` plan forge and manor-order purchases. Its one link to
  the settlements is the coins smiths pay caravan traders for ore. The candidate imported less iron ore (281 against 353), so
  caravan coins out were 4,091 against 4,480, and the settlements ended poorer in total (10,431 coins against 10,931). If
  money drove settlement hunger, that would mean more hungry settlers in the candidate, not fewer. The run shows the opposite,
  so this link does not explain the gap.

No gate on arrivals or births reads anything the two commits change. The commits change the world early (smith plans run from
day 1; the first differences show by day 10), and the rest follows by divergence.

## 4. Seed 2 swings both ways with other, unrelated changes

| campaign (commit) | seed 2 alive at day 365 | seed 2 arrivals | seed 1 alive at day 365 |
|---|---|---|---|
| 42734194963 (acc24b2, before batches 3-4; no F015/P99) | **189** | 73 | 324 |
| 42760291468 (b57261f, batch 3) | 322 | 162 | 341 |
| 42788018729 (fbfd6ad, baseline) | 316 | 167 | 339 |
| 42832338970 (3d515d6, candidate) | **203** | 90 | 318 |

Without F015 or P99, seed 2 already ended at 189 with 73 arrivals, which is the candidate's basin. Batch 3 then moved it to 322.
Seed 2 has two outcomes: either the settlements collapse and the village takes in their hungry households, or they do not.
Code changes that have nothing to do with migration move it from one to the other. Seed 1 stays within 318-341 across all four
commits.

## 5. Verdict

**This is a legitimate outcome, not a defect (WDR-022).** The fall in births and arrivals comes from the off-map settlements'
own course: in the baseline, Bourton collapsed and Wulstead declined. Their destitute households moved to the village by the
approved hunger rule, and births followed the couples who came. Nothing in F015 or P99 reads into the arrival rule, the birth
rule or the settlement economy, except P99's ore purchases, and they point the other way. Seed 2 reached the same low basin
(189) without these commits.

No fix is proposed. The starvation and smith improvements can be kept as they are.

## 6. What could not be established

- **Single run pairs only.** The local controlled reproduction was not run: the machine's disk is full (23 MB free), so the
  worktrees could not be checked out. One test would settle it: seed 2 on fbfd6ad with a neutral perturbation (for example, one
  extra `w.rng` draw on day 1), plus seeds 3-4 on both commits. That needs a dispatch or disk space, which is a lead or owner
  decision.
- **Birth rate per couple.** The lower births per "could" couple-day after day 180 (0.029 against 0.041) is not explained.
  It comes from coarse 10-day snapshots and no changed code feeds the birth rule. It was not traced through the recorder
  archive.
- **Smiths' ore purchases.** The candidate's smiths imported about 20% less iron ore on seed 2 (281 against 353; iron bars made
  478 against 546). This is worth checking on seed 1 and more seeds, to rule out `buy_held` holding back purchases a smith
  could later afford. It does not bear on the population difference.
