# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 2 |
| APPROVED | 231 |
| PROVISIONAL | 2 |
| SUPERSEDED | 2 |
| REOPENED | 0 |
| DEFERRED | 1 |

## Build 20: Living Economy: open, reopened or provisional (3)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ARMOR-CATALOG-D1 | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials option A or B for Build 22, the example values (the rest by the same rules), and whether the cloth headgear is included (docs/design/ARMOUR_CATALOGUE_PROPOSAL.md) | PROVISIONAL | no | ARMOR-CATALOG-01, ARMOR-MATERIALS-01 | docs/design/ARMOUR_CATALOGUE_PROPOSAL.md |
| MP-INTERACT-Q1 | Player-to-player contracts: the contract system only has a way for villagers to do units of work, so contracts between two players are limited to goods. Should a player be able to hire another player for work (a service contract)? | OPEN | no |  | MP-INTERACT-01 worker report and audit (wip/x20-mp-interact 0ce4c9e) |
| MP-INTERACT-Q2 | Talk targeting: Talk takes the nearest person, so a closer villager comes before another player (a tap, a click or Next always reaches the player). Should players come first for Talk instead? | OPEN | no |  | MP-INTERACT-01 worker report (wip/x20-mp-interact 0ce4c9e) |

## Approved, no build assigned: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |

