# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 1 |
| APPROVED | 239 |
| PROVISIONAL | 2 |
| SUPERSEDED | 2 |
| REOPENED | 0 |
| DEFERRED | 4 |

## Build 20: Living Economy: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ARMOR-CATALOG-D1 | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials option A or B for Build 22, the example values (the rest by the same rules), and whether the cloth headgear is included (docs/design/ARMOUR_CATALOGUE_PROPOSAL.md) | PROVISIONAL | no | ARMOR-CATALOG-01, ARMOR-MATERIALS-01 | docs/design/ARMOUR_CATALOGUE_PROPOSAL.md |

## Future backlog (Build 20 or later, not assigned): open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| X20-TRADER-PAY | Settlement traders reopen (X20-SETTLE-REOPEN) but close again within weeks: a trader keeps its till at its reserve (0.85 x starting till) and pays its household only from coins above it, so the household earns almost nothing and switches trade (Build 24's own rule). Trading stays well below Build 24 (day-60 village coins 4191 vs 5429 seed 1; 4083 vs 5236 seed 2), conservation exact. Options: (a) keep as is (legitimate outcome under WDR-022); (b) change the trader pay rule (e.g. pay the working household a share of turnover or a floor wage before holding the reserve), a retuning that needs approval. Lead recommendation: (a) for the next playtest, measure, revisit with the Living Economy wage work (LE-04 negotiated wages, off). | OPEN | no |  | docs/directives/2026-10-30_x20_trader_close_decision.md |

## Approved, no build assigned: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |

