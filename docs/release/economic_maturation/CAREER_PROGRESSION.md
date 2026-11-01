# Career Progression, NPC Ambition, and Skilled Employment (X20-CAREER-AUDIT)

Section of the Economic Maturation Audit (X20-ECON-MATURE). Owner directive 2026-11-01,
`docs/directives/2026-11-01_career_progression_audit.md`. Read-only: code at `ae8641d` (the chapel correction on the Build 25
source; the career code is the same as `ad281dc`), the register and directives, and the three 365-day runs (Actions 41279031310
normal seeds 1 and 2; 41279051834 Living Economy on, seed 1). No gameplay code was changed. `NB` = `game/scripts/core/npc_brain.gd`.

## Answers

**Does the game have a functional experience-driven career progression system in which NPCs actively pursue advancement?**
No, not in normal play. Villagers gain experience and skill through work, and skill makes them faster, unlocks recipes and raises
manor job-board pay. Career movement, though, is sideways and driven by necessity: NPCs look for work only when unemployed, short of
a tool, or when their household cannot get by, and they choose by pay, tool cost and distance, never by skill. There are no
promotions; apprentice, journeyman and master are labels (owner X18-D3: "No thresholds; names in reports"). The owner-approved
ambition layer (WDR-011-Q2 option B, the `job_choice` profile) is built but switched off, pending the open owner decision X19-SWITCHES-D1.

**Why aren't advanced skilled jobs increasing as the settlement develops?** Because nothing creates them. Skilled posts are capped
at the starting count (`staff_target` = `Population.JOBS`, NB:4482) and refilled only on death, retirement or departure; they never
appear in the labour market, and no villager can build a workshop or found a business (F-1 deferred, OD-LE-04 future). Adults grew
from 60 to 148-204 while employed adults stayed at 51-63. Ore exhausted by day 180, a fixed money supply limiting manor hiring, and
traders at zero coins are legitimate constraints (WDR-022); the flat skilled headcounts come from the design limit, not a malfunction.

## 1. Existing career-progression architecture

| Stage | What exists | Where |
|---|---|---|
| Skill development | XP from work: farming and husbandry acts, mining, felling, crafting, trading, healing; levels 1-10 with tier effects | `Skills.gain` (skills.gd:102); world.gd 722, 2331, 2340, 2391, 2001; NB:2679; data/skills.json |
| Work experience | days worked per industry, read by the capability hook (work time, job-board pay) | settlement/experience.gd:107; settlement/capability_hook.gd:15-24 |
| Job movement | `seek_work` (NB:4334-4402) among floor jobs; `_change_job` (NB:4414) | 190 / 201 / 200 job changes a year |
| Skilled trades | fixed headcount kept at strength by succession and apprentices (NB:4476-4615) | B8-016, EQ-04 (COMPLETE) |
| Ambition | R5 aspirations and the `job_choice` profile (judgment/judgment_aspiration.gd; judgment_live.gd:1001-1053 `pick_job`) | OFF: `aspiration.enabled false`, `integration.job_choice false` |
| Economic expansion | household stalls and storefronts; a single stonecutter place; no workshops, businesses or production employers | stalls.gd:470-508; business.gd:234; construction places only from the UI |

## 2. Implemented versus missing (the 18 mechanisms)

| # | Mechanism | Classification | Evidence |
|---|---|---|---|
| 1 | Occupational experience | Implemented but not verified | `_note_work` → `WorkExperience.credit`; feeds `CapabilityHook`. No per-person record in the runs |
| 2 | Skill improvement through work | Implemented but not verified | `Skills.gain` call sites above; manor hands' mending and hauling earn none; no skill data in the runs |
| 3 | Apprenticeships and training | Partially implemented | "apprentice" is a succession label taking effect at once (NB:4577-4593), no master, period or skill check; owner E22-OD-03 (D27 answer C): teaching and apprenticeship are FUTURE |
| 4 | Journeyman / intermediate | Partially implemented | rank names only (`Skills.rank`); X18-D3 no thresholds |
| 5 | Master qualifications | Partially implemented | recipes gated by level (world.gd:2352, NB:1404): smithing and crafting to 5, tanning 4; level 10 flavour |
| 6 | Aspirations and ambition | Implemented but blocked (switched off) | `job_choice_allowed()` (judgment_aspiration.gd:598) refuses while the layer is off; X19-SWITCHES-D1 OPEN |
| 7 | Recognising opportunities | Partially implemented | `job_market` (NB:4146-4192) lists only manor hand, farmer, woodcutter, hunter, miner, prospector, stonecutter, tailor, barber, clergy |
| 8 | Seeking advancement | Partially implemented | `seek_work` runs only for the unemployed, those short of a tool, a hunter without game, or a member of a household unsustainable 3+ days earning below their share (NB:4351-4358) |
| 9 | Promotions within a workplace | Not implemented | no ranks or posts inside a trade |
| 10 | Career changes and retraining | Fully implemented and functioning (sideways only) | `_change_job`; PAR-01B: experience neither granted nor reset on a change |
| 11 | Wage progression | Implemented but not verified | job-board pay (manor_work.gd:551) and harvest quests (quests.gd:159) scale with experience; manor wage raise (NB:4236) never fired (`wage_offers_raised` 0); negotiated wages off (economy.json) |
| 12 | Advanced production by skill | Implemented but not verified | recipe gates and tier effects (world.gd:2352, 2370-2383); no gated-recipe counts in the runs |
| 13 | Self-employment | Partially implemented | stonecutter (one place), household stalls, hunters, merchants |
| 14 | Founding workshops, shops, businesses | Partially implemented (workshops: none) | villagers build houses, lofts, stalls; never workshops (`workshops_built` 0); F-1 DEFERRED; OD-LE-04 FUTURE (econ_actor.gd:35-37 placeholder); PVG-05 NOT STARTED |
| 15 | Hiring apprentices or employees | Partially implemented | households hire building helpers only; EMP-PERM-01 NOT STARTED, placed in Build 26 for planning |
| 16 | Replacing retired or dead skilled workers | Fully implemented and functioning (headcount) | smith 2, carpenter 2, tanner 2, cook 3, merchant 6 held all year through 77-83 old-age deaths; sage fell 1 → 0; guards 6 → 1-2 (treasury-limited) |
| 17 | Mobility between wealth levels | Implemented but not verified | incomes, inheritance, household splits exist; no household panel to measure movement yet |
| 18 | Constraints on advancement | Fully implemented and functioning (binding) | `staff_target` cap; resource caps on floor jobs; treasury runway for manor hands; tool cost; change cooldowns |

## 3. Skill development and promotion

- Skill to output: connected (tier effects, recipe gates, `CapabilityHook.work_time`).
- Skill to pay: partly (job-board and harvest-quest wages only).
- Skill to job choice: not connected. `seek_work` scores pay minus tool cost/10 minus distance/60; skill terms live only in the switched-off `pick_job`.
- Skill to filling a vacancy: not connected. `_apprentice_for` (NB:4577-4589) chooses by current job (none, manor hand, labourer), household and id; someone already in another trade cannot fill the post.
- Skill to opening a business: no path.

## 4. NPC ambition and career decisions

The R5 layer has six domains, a profession priority and `skill_fit`, `growth_fit`, `profession_sat`
(judgment_aspiration.gd:320-354); `job_choice` weights in judgment.json:153. The owner approved the design (WDR-011-Q2 option B: a
job_choice profile behind its own flag, no separate career simulation, no hardcoded occupation preference); switching it on is the
open X19-SWITCHES-D1. The year-long runs did not pass `--aspiration` or `--job-choice`. Today `seek_work` uses the household's
unsustainable streak and the person's share of its cost, their own 5-day income, coins (for a tool) and distance; not personality,
age, skill or aspiration. Guards, reeve, sage, tailor, barber and clergy never seek.

## 5. Apprenticeship and advanced trade progression

Apprenticeship today is succession: when a skilled worker dies, retires or leaves, an unemployed adult (else a manor hand, else a
labourer) takes the post at once. There is no training period, master pairing or qualification. Teaching and apprenticeship as
gameplay are owner-approved as future scope (E22-OD-03).

## 6. Individual villager career histories

Not available. The flight recorder was off (`RECORD: false`), the digests are 10-day aggregates without person ids or skills, and the
logs have no job-change lines. No individual career can be reconstructed from the existing evidence. What the aggregates show
(days 0 / 90 / 180 / 270 / 365):

| Job | Normal s1 | Normal s2 | Economy on s1 |
|---|---|---|---|
| Unemployed adults | 0/8/11/35/94 | 0/2/25/35/129 | 0/11/19/48/141 |
| Farmer | 10/12/12/12/12 | 10/12/12/12/12 | 10/12/12/12/12 |
| Manor hand | 0/6/10/9/8 | 0/6/8/13/0 | 0/8/10/10/5 |
| Miner | 8/8/6/1/5 | 8/9/7/2/6 | 8/6/4/4/8 |
| Woodcutter | 6/4/3/1/1 | 6/5/3/2/2 | 6/2/5/5/4 |
| Hunter | 4/1/4/5/4 | 4/4/5/6/5 | 4/4/5/6/6 |
| Guard | 6/6/1/2/2 | 6/6/1/2/2 | 6/6/4/6/4 |
| Smith / carpenter / tanner / cook / merchant | 2/2/2/3/6 throughout | same | same |

Minimum observation-only instrumentation to follow careers (proposed, not yet added): a per-person panel at each checkpoint (id,
household, role, age, job, job start, xp per skill, work-experience days, coins, 5-day income, cumulative earnings); events for job
changes (from, to, trigger, options and scores; the flight recorder's `job_changed` already records from, to and why), vacancies
filled (with the candidate's skill), level-ups, gated recipes first made, stalls built and helpers hired; household cash by household
id. The development snapshot added under X20-ECON-LONGITUDINAL (households one by one, skills by level, jobs with summed skill, open
places) follows households and distributions but not individuals.

## 7. Skilled-employment bottleneck

| Candidate cause | Verdict | Evidence |
|---|---|---|
| Workers not gaining skills | Unknown, likely not | xp is gained in code; children come of age with no skills (life.gd:245-253); no skill data in the runs |
| Qualified workers exist but cannot advance | Supported structurally | skilled trades never in `job_market`; a vacancy is the only way in |
| Advanced positions unavailable | Supported: main cause | `staff_target` = starting count; smith, carpenter, tanner, cook, merchant flat for 365 days in every run |
| Employers do not recognise qualified candidates | Supported | `_apprentice_for` ignores skill |
| Hiring does not create positions | Supported | vacancies open only below starting strength (NB:4513, 4526) |
| Businesses cannot expand | Supported (design limit) | no workshops; F-1 deferred; OD-LE-04 future |
| Skilled villagers cannot open businesses | Supported (design limit) | only household stalls and the stonecutter place |
| NPCs lack logic to pursue advancement | Supported | necessity-driven `seek_work`; ambition off |
| Economic and resource constraints | Supported (legitimate) | iron, coal, copper ore 0 by day 180; coins 5,586-6,914 while population roughly tripled; treasury limits manor hands; traders at 0 coins |
| Job limits fixed or wrongly enforced | Fixed by design, enforced correctly | no enforcement bug; farmers at 12 = 2 per field |
| Population outpacing employment | Supported | adults 60 → 148-204; employed 54 / 51 / 63 |
| Harness not exercising progression | Supported | recorder off; no `--aspiration`/`--job-choice`; negotiated wages off |

## 8. Advancement and business creation

Not connected: no skill level, savings or ambition leads a villager to found a workshop or employ others. Household stalls and
storefronts are the only villager-created outlets. Business founding (OD-LE-04), NPC workshop construction (F-1) and production
employment (PVG-05, EMP-PERM-01) are deferred or future by owner decisions.

## 9. Effects on household income and markets

Not measurable from the existing runs for individuals. Aggregates: household cash total rose (2,664 → 4,760-6,463) but fell per
person (25.6 → 15-18); lowest-decile household cash went 43 → 4 (s1), 34 → 133 (s2), 43 → 19 (economy on). Without new skilled
capacity, the growing adult population mostly enters manor work or unemployment.

## 10. Confirmed defects and missing connections

Defects (minor, agent-level):
- `settlement/experience.gd:3-6` says the experience record is never read, contradicting `capability_hook.gd:15-18` (documentation).
- `skill_start.job_skills` maps carpenter and tanner to `crafting`, though SKILL-TRADES-18 moved their work to `carpentry` and
  `tanning`; farmer and stonecutter have no entry. `skill_fit` and `profession_sat` would read stale skills; latent while job_choice is
  off. A fix belongs in `skill_fit`'s own mapping, since `job_skills` also seeds new worlds.

Missing connections (design limits, not defects): fixed skilled-post count (B8-016 keeps strength, does not grow it); no skill term in
`seek_work` or `_apprentice_for`; ambition off; no NPC workshops, businesses or production employers.

## 11. Recommended corrections, by economic impact (all need owner decisions; none implemented)

1. Tie skilled capacity to real demand instead of the starting count: list skilled trades in `job_market` with places from existing
   signals (a free forge, anvil or workbench; unmet buyer demand: traders unable to buy, open needs, tool orders) and fill them through
   `seek_work` and succession. Revises B8-016/EQ-04 `staff_target` (DCR-01: intentional revision); relates to LE-03 and WDR-012.
2. Let villagers build workshops and found businesses through the existing construction, till and ownership rules (F-1, OD-LE-04, PVG-05).
3. Decide on enabling R5 job_choice after a measurement run with `--aspiration --job-choice`, extending its options to item 1's places (X19-SWITCHES-D1).
4. Skill-aware succession: prefer recorded skill in the trade, allow candidates from other trades, pair with a surviving master (E22-OD-03, B8-016 revision).
5. NPC businesses employing workers through the existing wage systems (EMP-PERM-01 scope, OD-LE-04).
6. Wage progression: negotiated wages (OD-LE-03 D02 FUTURE; X20-SERVICES-SCOPE OPEN).
7. Observation-only career instrumentation (section 6) and the two minor fixes (section 10): agent-level under X20-CAREER-AUDIT.

## 12. Owner decisions required before implementation

X19-SWITCHES-D1 (aspirations and job_choice on); a revision of B8-016/EQ-04 skilled headcounts; F-1 and OD-LE-04 (workshops and
business founding); E22-OD-03 (apprenticeship and teaching); EMP-PERM-01 scope (NPC employers); OD-LE-03 D02 and X20-SERVICES-SCOPE
(negotiated wages and services).
