# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 1 |
| APPROVED | 237 |
| PROVISIONAL | 2 |
| SUPERSEDED | 2 |
| REOPENED | 0 |
| DEFERRED | 4 |

## Build 20: Living Economy: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ARMOR-CATALOG-D1 | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials option A or B for Build 22, the example values (the rest by the same rules), and whether the cloth headgear is included (docs/design/ARMOUR_CATALOGUE_PROPOSAL.md) | PROVISIONAL | no | ARMOR-CATALOG-01, ARMOR-MATERIALS-01 | docs/design/ARMOUR_CATALOGUE_PROPOSAL.md |

## Approved, no build assigned: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |

## Multiplayer track (isolated branch): open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| MP-INET-RELAY | Internet multiplayer beyond free methods: hosts on mobile data or behind carrier-grade NAT cannot be reached by invite code, UPnP or port forwarding. Options: (A) free methods only, as built (no cost; those hosts cannot host); (B) hole punching via free public STUN servers (no cost; third-party dependency, a second code from guest to host, still fails on much mobile data); (C) our own small rendezvous+relay server (covers every network incl. phone hosting; a small cloud server plus bandwidth each month, price to be quoted; recommended, with an owner-set spending cap); (D) a commercial relay service (new SDK, accounts, fees above a free tier); (E) Steam networking (excluded now; no Android). Default until decided: A. Note: the 2026-10-24 decision MP-D5 says free methods first, no relay, no paid service, so B-D would revise it (DCR-01). | OPEN | no |  | BATCH_D_CONNECTIVITY.md in docs/multiplayer on wip/expansion20 (Batch D connectivity study, 2026-10-30) |

