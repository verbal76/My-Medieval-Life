# X20-BANDIT-AI and X20-JUDG-C3: investigation and validation report

Owner directives 2026-10-31 (`docs/directives/2026-10-31_sjdh_c4_bandit_intelligence.md`, SJD-H C4;
`docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md`, C3). Branch `wip/x20-bandit-ai` (base `531da40`). Design:
`BANDIT_AI_DESIGN.md`. Developer reference; the player-facing text is the wiki's Bandits page (updated).

## 1. Evidence used

| Evidence | Commit | What it gives |
|---|---|---|
| Actions 41129188776 / 41129193143 (SJD-G, judgment on / off, 365 days) | `d0f623b` | totals only: bandits killed 234 / 143 on, 6 / 7 off (artifacts cannot be downloaded here) |
| Recorder archive, 8 days seed 1 (SJD-G) and a target-setter trace, 4 days seed 1 | `de8d225`, `131d632` | who sets a bandit's target and why; the re-robbing loop |
| `game/tests/bandit_diag.gd` (read-only): `BANDIT_DEATH` per death, `BANDITS` per checkpoint | `131d632`, corrected `c664b31` | phase and attackers of each death, robberies, re-robberies, retreats, numbers in sight, bandit-days, lifespan |
| Local 60-day runs, old behaviour, seeds 1 and 2 | `131d632` + diag | 4 and 4 deaths, by phase |
| Actions 41171898332, 365 days, seeds 1 and 2, judgment on | `c664b31` (first behaviour) | per-death data, per capita, villagers slain |
| Local 60-day runs, final behaviour, seeds 1 and 2 | `6db980a` | after the three corrections below |

## 2. The owner's validation questions (old behaviour)

| Question | Finding |
|---|---|
| Deaths during active robberies or assaults | Few. Local 60 days, old behaviour: 3 of 8 deaths while "fighting back" (a guard or two on it). The robbery itself never killed a bandit: a bandit robbing was the one not fighting |
| Deaths during organised retaliation or pursuit | The family defenders (FAMILY-01) and guards; organised (two or more on it) 2 of 8 locally |
| Deaths after disengaging | The main mode: bandits that had broken off, hurt, caught on the way or at the camp. Locally 5 of 8 "caught retreating"; in the first new-behaviour year (41171898332) 52 of 72 and 34 of 54 deaths were hurt bandits killed resting or lurking at their own camp by family defenders who followed them there |
| Do bandits recognise numerical disadvantage? | No: no bandit code counted hostiles or allies |
| Do they attempt retreat? | Only below 30% health (fight() gives up and walks to the camp) |
| Does retreat succeed? | Rarely in the open: pursuers chase at 1.3x walking speed, the retreat walks at 1.2x; it escapes when the chaser is blocked by terrain, passes 25 tiles, or is a guard nearing the camp. Struck on the way it is retargeted, gives up again, and makes for the camp: a retreat with no memory of itself; at the camp "retreat to the camp" is standing still |
| Do they cooperate defensively? | No: bandits had no ties (excluded from Relations' shared hours) and no aid rule |
| Does repetitive robbery inflate encounters? | Yes, a defect: the robbery branch ran on any non-guard villager a bandit struck, so a victim or defender who struck back was "robbed" every two game minutes, down to robberies of nothing, while their blows landed on a bandit that never fought back (trace: 4-day seed 1, 14 robberies, 6 of them re-robberies of the same victim). Separately, prey choice picked the same victim nearest the camp again and again |
| Does respawning inflate annual mortality? | Yes in the count, by design: 2-3 outlaws arrive one season (2 game days) after the last bandit dies, so a wiped band is replaced every few days. In the year of 41171898332 (first new behaviour): 56 and 73 bandits seen (50 and 67 outlaw arrivals), each living 12.8 and 12.7 days on average before dying: 0.61-0.62 deaths per bandit-year. The 143-234 annual deaths are many short-lived arrivals, not a large standing band (6 at the start). The respawn rule is unchanged |

## 3. Behaviour changes

See `BANDIT_AI_DESIGN.md`. In short: the bandit's danger is weighed through the judgment system (press, retreat to the camp or
out of it when attacked there, break out past a blocker, defend a fellow bandit by bond), with perception from sight,
experience from routs (practical wisdom), losses known from death news passed in the band's shared hours; a bandit robs, it
does not stay to kill villagers who turn on it; no robbery of anyone fighting the band; no re-picking a victim robbed within
6 hours. Nothing changes health, damage or speed. Off switch `decision.integration.bandit_danger`.

## 4. Results

### First behaviour (`c664b31`), Actions 41171898332, 365 days

| | Seed 1 | Seed 2 |
|---|---|---|
| Bandit deaths (old behaviour, 41129188776) | 54 (234) | 72 (143) |
| Villagers slain by bandits (old) | 42 (0) | 33 (0) |
| Bandits seen; outlaw arrivals; mean lifespan of the dead; deaths per bandit-year | 56; 50; 12.8 days; 0.61 | 73; 67; 12.7 days; 0.62 |
| Deaths by phase | caught retreating 25, disengaged 28, fighting back 1 | caught retreating 36, disengaged 36 |
| Deaths by who | family 44, organised 4, guard 3, starvation 3 | family 63, organised 5, guard 1, starvation 3 |
| Retreats begun / survived | 75 / 50 | 140 / 104 |
| Bandits going to a fellow's aid; defend choices | 99; 140 | 112; 74 |
| Robberies; of nothing; same victim again within 30 min | 146; 13; 66 | 182; 8; 95 |
| C3: blows folded into an existing assault incident; attempted robberies | 210; 13 | 207; 8 |
| Conservation | leak 0, item leaks none, 0 script errors | same |

This run found the three problems corrected in `6db980a`: villagers killed by bandits pressing fights against the villagers
who turned on them; the at-the-camp death mode; prey choice re-picking a victim.

### Final behaviour (`6db980a`), local 60 days (old behaviour, `131d632`, in brackets)

| | Seed 1 | Seed 2 |
|---|---|---|
| Villagers slain by bandits | 1 (0) | 0 (0) |
| Bandit deaths | 4 (4) | 1 (4) |
| Retreats begun / survived | 15 / 13 | 5 / 5 |
| Same victim robbed again within 30 min | 0 | 0 |
| Defend choices | 102 | 104 |
| Conservation | leak 0, no item leaks | same |

The year-long comparison of the final behaviour is pending the lead's dispatch.

## 5. G0

The diagnostics commit `131d632` is world-identical to `docs/release/sim_baseline.json` (seeds 1 and 2, days 10 and 30: same
fingerprint, villagers alive and currency; local). The behaviour commits change G0, as the lead expected (bandit behaviour
in the default game), with currency leak 0 and no item leak at every checkpoint; the baseline is to be replaced once at
integration.

## 6. Tests

`bandit_ai_test` 17 checks (written to fail first: 6 fail with the layer off, the 4 added after the first comparison fail on
`c664b31`); `judgment_incident_test` 15 (11 failed before C3); on the final code (`6db980a`): combat, family_first, sim_f3, outlaw_return, od16, justice,
recorder (214), world (339), judgment_live, judgment_incident, wiki; on `967c59a` also family, pursuit, manhunt, judgment_x19,
judgment_soak, dialogue_perspective.
