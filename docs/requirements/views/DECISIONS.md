# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 2 |
| APPROVED | 239 |
| PROVISIONAL | 2 |
| SUPERSEDED | 2 |
| REOPENED | 0 |
| DEFERRED | 5 |

## Build 20: Living Economy: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ARMOR-CATALOG-D1 | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials option A or B for Build 22, the example values (the rest by the same rules), and whether the cloth headgear is included (docs/design/ARMOUR_CATALOGUE_PROPOSAL.md) | PROVISIONAL | no | ARMOR-CATALOG-01, ARMOR-MATERIALS-01 | docs/design/ARMOUR_CATALOGUE_PROPOSAL.md |

## Future backlog (Build 20 or later, not assigned): open, reopened or provisional (2)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| LE05-RENTAL-REPAIR | LE-05 tool repair and rental (OD-LE-08 direction approved; worker A's proposal on wip/x20-le05, nothing built; wear now travels with tools, X20-WEAR-TRANSFER): approve building, behind the Living Economy switch, (1) repair at an anvil by a smith or the player costing ceil(input x missing share) of the item's own forge recipe and the same share of minutes, items without a forge recipe not repairable; (2) rental by workers short of a tool from holders with a spare, deposit = the tool's value, daily fee = the value share its wear consumes per working day, deposit escrowed in World.transactions, forfeited if the tool breaks or is not returned, settled to the estate on death; additive bounded save keys; nothing with the economy off. Repair as a shipped player recipe with the economy off would be a separate decision. | OPEN | no |  | docs/directives/2026-10-30_x20_background_development.md |
| SJD-H-CAL | SJD-H calibration package (worker D's SJD-G soak report on wip/x20-sjdg; defaults keep today's behaviour): C1 influence strength is barely visible in behaviour - keep until played, or raise deed severities? C2 permanent assault/killing memories for every hearer are 76-82% of memories and make the judgment save 4.4-5.8 MB a year - let hearsay assault memories fade while the judgment stays (murder unchanged)? C3 every blow and every robbery in a spree counts separately (a robbery that took nothing included) - one deed per episode via the existing fight window, no theft when nothing taken? C4 family danger: fight vs shield flips between seeds and judgment-on kills 143-234 bandits a year vs 6-7 off - intended? C5 mixed feelings (SJD-Q04) has weight 0 so it is not in behaviour - leave, or weight it on decayed values? C6 confirm the approved decay works as described. Also: bandits re-rob the same victim every 2 game minutes until nothing is left - intended? | OPEN | no |  | docs/directives/2026-10-30_mp_batch_d_decision.md |

## Approved, no build assigned: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |

