# Expansion 18: owner decisions pending, in dependency order

Prepared 2026-10-22 by the Expansion 18 worker (`wip/expansion18-preparation`) for the coordinator to put to the owner
one at a time (directive `docs/directives/2026-10-22_expansions_18_19_20_directive.md`). **Update 2026-10-23: D2 to D9 are ANSWERED by the owner (option 1 for D2 and D3; the table for D4; interpolate for D5;
set at acceptance for D6; by ground cut for D7; round to nearest for D8; as now for D9) and implemented on
`wip/b18-capability`; see PROGRESS.md. The text below is the record of the options as put.** (Original header: nothing
below was decided or implemented.) Every recommendation is an agent proposal. Approved so far: Q18-9, Q18-10, Q18-11 structure, Q18-11A
(the `approved` profile, X18-CAPNUM), Q18-11B (workforce and effective levels), X18-CAPCOMP part 1 (experience by hours,
caps, straight-line level, hours-weighted workforce report; each worker's own level is the basis of their performance
and pay).

Why the order: the per-worker modifiers cannot be switched on until every worker has an effective level, which needs
D1 (where experience starts; decided 2026-10-22) and D2 (what limits it). D3 says what the levels are used for beyond pay and output. D4 to
D6 decide how hours and levels feed the modifiers. D7 to D9 are smaller follow-ons that become live when the hook is
switched on.

Figures quoted come from one game day of seed 1 on this branch (`experience_test`, `test_live_world`): mining 54 hours
by 11 workers (about 5 h each), forestry 14 h by 6, smithing 14 h by 3, farming almost none on day 1 (nothing is ripe
yet). One day is a thin sample; the times to reach a cap below are rough.

---

## D1. Starting experience: DECIDED (owner, 2026-10-22; implemented)

Option 2 with farming sub-option (a), `docs/directives/2026-10-22_x18_d1_starting_experience.md`. Once, for a new world
and for a save with no experience section: starting days = cap x recorded skill level / 10 in the industry's skill
(mining, woodcutting -> forestry, smithing, crafting -> carpentry and tanning, trading -> trade), only where the person
holds xp in that skill; farming from the PAR-01A working history (a farmer's PAR-01A tenure, xp_per_year, the skills'
curve). The player gets none (PAR-01A). Seed 1: 30 person-industries seeded; the smiths start at experience levels 8 and
6; the ten farmers at farming levels 3 to 8 (5.4 to 14.4 days of 18). Details: DESIGN.md section 9b.

## D2. Facility limitations (the effective level): FINAL FORM

**Facts (after D1).**
- Every established villager now starts with an experience level in their trade (seed 1: smiths 8 and 6, farmers 3-8,
  miners and woodcutters by their Skills). With the live hook on and no facility limit, their approved gains apply
  from the first day (e.g. +13.8% and +11.9% faster smithing, up to +9.5% farm work rate).
- Each worker has an experience level and an effective level, kept apart by structure (effective is computed, never
  stored; `facilities.caps` is empty, so effective = experience; tested).
- What the game knows of facilities: stations by type and count, each with a number of places (a villager waits when
  they are full, or when the player works there); fields, fences, pens, market stalls; mining structures (pit ramps,
  timber supports with a condition); handcarts (wear); tools (durability, and a broken tool is gone).
- A missing facility already stops the work itself: no forge, no smelting; no field, no sowing. No station or building
  has a condition or quality: an existing station is always fully operational.
- The settlement model's threshold steps mix facilities with people, stock and other industries (e.g. smithing 2
  "toolmaking" needs a mine or iron bars in store), so they are not a facility measure as they stand.

**Decision.** What lowers a worker's effective level below their experience, if anything, now?

**Options and their effects on the village economy.**
1. **No facility limit while the game's facilities have no degraded state** (effective = experience). A facility is
   either there (the work happens at the worker's own level) or not (the work cannot happen at all), which is already
   the "available, operational" limit at the only grain the game has. Effect: the D1 levels act in full from the start;
   building a second forge or more stalls helps only through places and capacity, as today; no double penalty.
2. **A capacity cap**: when more workers are active in an industry than its facilities have places, everyone's
   effective level is scaled down (e.g. by places / workers). Effect: crowded trades lose speed twice (they already
   wait for a place) and pay falls with it; discourages sharing a workshop; needs numbers.
3. **Facility tiers per industry** (new data: e.g. a forge and anvil allow up to level 6, a forge, anvil and workbench
   up to 8, more up to 10), the cap read from what the settlement has built. Effect: masters in a poorly equipped
   village work below their experience (the seed-1 smiths would be held at 6 until a further facility is built), so
   building pays off in output and wages; every tier and number is a new owner decision, and losing a facility lowers
   everyone's effective level at once.
4. **A condition cap, later**: once facilities gain wear or damage (a SET-D building-condition rule, or Build 17's
   repair system extended to stations), a worn or damaged facility caps the effective level of whoever works at it.
   Effect: individual and fair (a master at a good forge keeps the advantage); ties capability to upkeep; needs the
   condition rule first.

**Recommendation: option 1 now, with option 4 as the rule to adopt when facilities gain a condition.** It is the only
option that uses facts the game already has without inventing tiers or numbers, it keeps D1's established differences
intact, and it avoids the double penalty of option 2. Option 3 would make the owner set a table of tiers for seven
industries before the hook can be switched on; option 4 gives "facilities limit effective capability, never experience"
real meaning once a facility can be in poor repair.

## D3. Thresholds

**Facts.** Two scales exist side by side. (a) The settlement model's **threshold steps** per industry (e.g. smithing 1
a smithy, 2 toolmaking, 3 master smithy; agent proposals, Q18-2), derived from people, tools and stations, used for
specialization, leaders and the regional model. (b) The approved **0-10 levels** (experience and effective), used for
pay and output. MIN-D keeps its own mining stages 1-4. The activity window is approved (any hours in 2 game days).

**Decision.** Should any threshold attach to the 0-10 levels (for example "an industry counts as established at
workforce level X", or a minimum level to be reported as a practitioner), and how do the threshold steps and MIN-D
stages relate to the 0-10 scale?

**Options.**
1. **No thresholds on the 0-10 levels**: the steps stay descriptive milestones (what the village can do), the 0-10
   levels only scale pay and output. Effect: no behaviour depends on a level crossing; nothing gates (Q18-9).
2. **Reporting bands only** (e.g. novice / journeyman / master names for level ranges in reports and the wiki).
   Effect: easier to read; no economic effect.
3. **Planning thresholds**: specialization and regional leadership use the workforce level instead of the steps.
   Effect: villages specialise by what their people have done, not only by what they own; changes the regional model.

**Recommendation: option 1, with option 2's names when reports reach the player.** It keeps Q18-9 ("never a gate")
intact. MIN-D's stages-to-0-10 mapping stays a reconciliation item.

## D4. Which industry unattributed work belongs to

**Facts.** Experience is credited from work steps through the capability hook's own mapping. These earn nothing today
(no industry chosen): trade at a stall (no work step: the trader idles at the stall, and selling and buying are
instant), slaughter, hunting, foraging and fruit picking, clearing ground, fencing farmland, building (sites, stalls),
the manor's survey, trial pits, open-pit excavation, tunnelling, shoring and backfill, hauling and carting, sampling and
assays, service-contract steps (pit digging, surveys), and the player's cancelled actions.

**Decision.** For each activity: which industry, if any?

**Options (per activity, proposed):**
| Activity | Proposed industry | Effect |
|---|---|---|
| Trade at a stall | trade, for the hours a trader keeps the stall open | Trade experience exists at all; otherwise trade's +10%/+4% can never apply |
| Slaughter | farming (keepers) | Small; keepers are farmers |
| Hunting, foraging, picking | none | No industry in the schema; keeps them out of the economy's capability |
| Clearing ground, fencing farmland | farming | Farm labour by the owner's F1 sense |
| Building (sites, stalls) | none until a construction or masonry industry exists (Q18-1) | Avoids crediting carpentry for stonework |
| Survey, trial pits, excavation, tunnelling, shoring, backfill, service-contract digging | mining | They are MIN-B..F mining work; MIN-D already counts diggers as mining practitioners |
| Hauling, carting | none (or trade) | Transport is not one of the seven industries |
| Player's cancelled actions | credit the seconds actually worked | Parity with villagers (credited per minute worked) |

**Recommendation: as in the table.** The largest economic effect is trade: without a choice its approved modifiers
can never act.

## D5. Level rounding for the modifiers

**Facts.** Individual levels are real-valued (e.g. 7.3); the approved tables give values at whole levels 0-10. The
prepared per-worker path takes the whole level below (floor), provisionally.

**Options.**
1. **Floor** (7.3 -> 7): benefits arrive in steps; a worker just short of a level gets nothing of it.
2. **Nearest** (7.3 -> 7, 7.5 -> 8): steps, half a level earlier on average.
3. **Interpolate** between the two whole levels (7.3 -> 30% of the way from 7 to 8). Smooth; every hour worked counts;
   no cliffs that would make NPC decisions jump.

**Recommendation: option 3.** It matches the straight-line progression the owner approved and avoids step effects.

## D6. Wages fixed when a job is posted

**Facts.** The manor posts quarry and mending jobs with a wage before anyone takes them; the wage is set aside from the
treasury then (manor job board). A per-worker modifier cannot be known at posting. The harvest hand's wage is set when
the player accepts (the worker is known).

**Options.**
1. **Posted wages stay at the base rate** (no modifier on posted jobs). Effect: the manor's jobs never pay experience;
   masters prefer other work.
2. **The wage is set when the job is taken**, at the taker's effective level (the treasury check moves to acceptance).
   Effect: fair to the worker; the manor's daily cost varies with who takes its jobs.
3. **Posted at base, a completion bonus** at the taker's level paid from the treasury when the job is done. Effect:
   same total as option 2 but two payments, and a bonus the treasury may not be able to pay.

**Recommendation: option 2.** It applies the owner's "individual experience is the basis of pay" with one payment and
no new money.

## D7. Crop shares when cutters work at different speeds (FARM-CROP-01, with the per-worker path)

**Facts.** On `wip/farm-cropshare` (not in this baseline) a field's crop is split by the minutes each cutter worked.
With per-worker work rates a master cuts the same ground in fewer minutes, so a minute-based share would give the
faster cutter less grain for the same work.

**Options.** 1. Share by minutes (as written). 2. Share by work done: minutes x the cutter's own work rate (base-minute
equivalents). **Recommendation: option 2** (no grain created or moved by the rate; each cutter's share follows the
ground they cut).

## D8. Whole coins

**Facts.** A +4% pay modifier on the 6-coin harvest wage gives 6.24, rounded back to 6; small wages show no modifier.
**Options.** 1. Round to the nearest coin (as now). 2. Round up whenever the modifier is above zero. 3. Carry fractions
per worker until they make a coin. **Recommendation: option 3** (exact over time, no coin created early).

## D9. When experience leaves

**Facts.** A villager's experience is dropped at the next dawn after death or departure; a returning emigrant would
start again at 0. **Options.** 1. As now. 2. Keep an emigrant's record for a set time in case they return.
**Recommendation: option 1** (the owner's "it leaves with the person"; returning emigrants do not exist in the game yet).

---

## Blocked items that need an owner decision before work can start

- **X18-STONECUT** (professional stonecutter) and **STONE-02..06** (own-use dressing, repair materials, efficiency by
  skill, the Stoneworking skill, the iron chisel): the stonecutter "uses the Stoneworking skill and the mallet plus iron
  chisel, the same as everyone", so it waits for: the starting Stoneworking levels and migration credit, the dressing
  efficiency values, chisel wear and the chisel recipe.
- **Q18-1** (skills for farming, carpentry, masonry, tanning), **Q18-2** (thresholds and first industries), **Q18-3**
  (closed purse or regional income), **Q18-4** (off-map regions), **Q18-5** (barter and credit), **Q18-6** (abstract
  regions and "different profiles"), **Q18-7** (migration out), **Q18-8** (SET-E stays 20+): needed for SET-C live
  trade and SET-D growth.
- **Q18-14** (which skill lets a courier notarise), **Q18-15** (which businesses are "major" for their own booth),
  **Q18-16** (where the village booth stands with no free stall), and the courier fee coefficients: needed before the
  courier booths go live.
- **MIN-D stages to 0-10**: a reconciliation item; until then mining's multipliers stay 1.0 in the game.
- **CAP-TOOLHOLDER**: recorded for design review only (owner: keep the implementation, no separate rule).
