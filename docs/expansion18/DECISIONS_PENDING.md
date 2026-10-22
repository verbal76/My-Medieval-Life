# Expansion 18: owner decisions pending, in dependency order

Prepared 2026-10-22 by the Expansion 18 worker (`wip/expansion18-preparation`) for the coordinator to put to the owner
one at a time (directive `docs/directives/2026-10-22_expansions_18_19_20_directive.md`). **Nothing below is decided or
implemented.** Every recommendation is an agent proposal. Approved so far: Q18-9, Q18-10, Q18-11 structure, Q18-11A
(the `approved` profile, X18-CAPNUM), Q18-11B (workforce and effective levels), X18-CAPCOMP part 1 (experience by hours,
caps, straight-line level, hours-weighted workforce report; each worker's own level is the basis of their performance
and pay).

Why the order: the per-worker modifiers cannot be switched on until every worker has an effective level, which needs
D1 (where experience starts) and D2 (what limits it). D3 says what the levels are used for beyond pay and output. D4 to
D6 decide how hours and levels feed the modifiers. D7 to D9 are smaller follow-ons that become live when the hook is
switched on.

Figures quoted come from one game day of seed 1 on this branch (`experience_test`, `test_live_world`): mining 54 hours
by 11 workers (about 5 h each), forestry 14 h by 6, smithing 14 h by 3, farming almost none on day 1 (nothing is ripe
yet). One day is a thin sample; the times to reach a cap below are rough.

---

## D1. Starting experience (new worlds and existing saves)

**Facts.** Tracking starts empty: today every villager and the player is at experience level 0 in every industry until
they work. The villagers already carry other records of their trade: their **Skills** (xp and levels per skill;
seeded once at world creation by PAR-01A, e.g. the seed-1 smiths are smithing 8 and 6), their **job** and **job_since**
(the day they took it up), and the PAR-01A tenure share. Skills map to industries as: mining -> mining, woodcutting ->
forestry, smithing -> smithing, crafting -> carpentry and tanning, trading -> trade; farming has no skill (Q18-1).
At about 5 hours of mining a day a miner reaches the 12-day cap (96 h) in about 20 game days; a smith at about 4.6 h a
day reaches the 24-day cap (192 h) in about 42 days.

**Decision.** What experience do people have when tracking begins: in a new world, and when an existing save is loaded?

**Options.**
1. **Start everyone at 0 (as now).** Simple and invents nothing. Effect: for the first few game weeks every worker is a
   beginner, so once the hook is on the village's output and pay are at the base and rise together as people work;
   the seed-1 master smiths are briefly no better than a new apprentice, which contradicts their Skills.
2. **Seed once from each person's Skills level in the industry's skill** (for example experience days = cap x skill
   level / 10, capped; farming from the farmers' job tenure, since it has no skill). Effect: established tradespeople
   start with their advantage (the seed-1 smiths, Skills 8 and 6, would start at experience levels 8 and 6: with the
   approved profile +13.8% and +11.9% faster work, +5.5% and +4.7% pay), newcomers start low; no sudden jump when the hook is switched on.
3. **Seed once from job tenure** (days in the current job x the working hours a day the trade averages, capped).
   Effect: rewards staying in a job; new worlds give everyone tenure 0 (as option 1) unless the world also seeds tenure.

**Recommendation: option 2, for both new worlds and loaded saves, applied once** (the same "one-time allocation, never
replacing recorded experience" rule as PAR-01A). It is the only option that agrees with what the game already says
about its people, it has no transition shock, and it adds no new data. Farming needs a sub-choice (tenure, or 0 until
Q18-1 gives it a skill).

## D2. Facility limitations (the effective level)

**Facts.** Each worker now has an experience level and an effective level, kept apart by structure (the effective level
is computed, never stored; `facilities.caps` is empty, so effective = experience). Facilities the game knows: stations
by type and count (forge, anvil, sawhorse, workbench, kitchen tables; each with a capacity of users), fields and their
fences, pens, market stalls, mining structures (pit ramps; timber supports with a condition), handcarts (with wear), and
tools (with durability). There is no condition or quality on stations and buildings.

**Decision.** What, if anything, lowers a worker's effective level below their experience?

**Options.**
1. **No facility limits for now** (effective = experience). Effect: experience alone sets performance; no facility
   matters beyond the existing needs (a smith still needs a forge to work at all). Simplest; invests nothing.
2. **A cap from the settlement's facility tier per industry** (the existing threshold levels: e.g. smithy / toolmaking
   / master smithy, each tier allowing up to a given effective level). Effect: a skilled smith in a village with only a
   basic smithy works below their experience until the village builds more; ties capability to infrastructure and makes
   building facilities pay off; numbers per tier needed.
3. **A cap from the facility the worker actually uses** (crowding: more workers than station places, or a worn or
   damaged facility where the game tracks condition, e.g. timber supports, carts, tools). Effect: local and fair to the
   individual (a master at a good forge keeps the advantage), but limited to what the game tracks today.

**Recommendation: option 1 now, option 2 as the long-term rule once SET-D adds building growth.** Option 2 gives the
"facilities matter" behaviour the owner described with data the game already has; option 3 is fragmentary today.

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
