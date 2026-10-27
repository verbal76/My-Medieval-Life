# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 6 |
| APPROVED | 232 |
| PROVISIONAL | 2 |
| SUPERSEDED | 2 |
| REOPENED | 0 |
| DEFERRED | 1 |

## Build 20: Living Economy: open, reopened or provisional (7)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ARMOR-CATALOG-D1 | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials option A or B for Build 22, the example values (the rest by the same rules), and whether the cloth headgear is included (docs/design/ARMOUR_CATALOGUE_PROPOSAL.md) | PROVISIONAL | no | ARMOR-CATALOG-01, ARMOR-MATERIALS-01 | docs/design/ARMOUR_CATALOGUE_PROPOSAL.md |
| MP-INTERACT-Q1 | Player-to-player contracts: the contract system only has a way for villagers to do units of work, so contracts between two players are limited to goods. Should a player be able to hire another player for work (a service contract)? | OPEN | no |  | MP-INTERACT-01 worker report and audit (wip/x20-mp-interact 0ce4c9e) |
| MP-INTERACT-Q2 | Talk targeting: Talk takes the nearest person, so a closer villager comes before another player (a tap, a click or Next always reaches the player). Should players come first for Talk instead? | OPEN | no |  | MP-INTERACT-01 worker report (wip/x20-mp-interact 0ce4c9e) |
| REG-X20-D1 | Off-map settlements: may a hungry household that is the only worker household of its business migrate for hunger (MIGRATE-18), and may it change trade? Today two undocumented agent rules forbid both (offmap.gd _move_jobs: 'a trade is never left with no household'; migration.gd _hunger_in: business with fewer than 2 workers excluded), so sole herders, miners, foresters and weavers whose goods find no buyer die with 0-2 coins while wheat is on sale. | OPEN | no |  | X20-FINAL settlement investigation 2026-10-27 (wip/x20-final eaf6652; probes in session scratch, no code change) |
| REG-X20-D2 | Off-map settlements: should 'cannot buy a day's food' (hunger migration) also count when there is no food for sale at all, not only when the household lacks coins? In the switches-on run Garton starved holding 68-110 coins with empty stalls after its farmers moved to better-paid trades. | OPEN | no |  | X20-FINAL settlement investigation 2026-10-27 (wip/x20-final eaf6652; probes in session scratch, no code change) |
| REG-X20-D3 | Off-map settlements: should settlement-to-settlement food trade get a live path? The owner's REG-BUY-D1 answer allows it, but road trade carries no food and RegionalMarket is not wired into the live game, so one settlement's surplus never reaches a starving neighbour. | OPEN | no |  | X20-FINAL settlement investigation 2026-10-27 (wip/x20-final eaf6652; probes in session scratch, no code change) |
| REG-X20-D4 | Off-map settlements: revisit the deferred circulation question (REG-CIRC-D1) now its prerequisites exist? Settlement traders keep buying from the village and buy little back (netherton paid out 460 coins in 30 days and took in 41), draining treasuries until relief and day labour stop. | OPEN | no |  | X20-FINAL settlement investigation 2026-10-27 (wip/x20-final eaf6652; probes in session scratch, no code change) |

## Approved, no build assigned: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |

