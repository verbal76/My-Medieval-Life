# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 1 |
| APPROVED | 238 |
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
| X20-TRADER-CLOSE | Review finding 1 (settlement traders): once traders close when nobody works them, all five settlement traders close by days 21-35 on seeds 1 and 2 and never reopen, ending caravan trade (village coins day 60: 5429->3995 seed 1, 5236->3848 seed 2; conservation intact; run 41133027134 on wip/x20-settle-food 108d252). Choose: (a) ship the fix as is; (b) add a rule that reopens a closed trader when a household takes up the trade again; (c) retune trader pay (excluded by the owner's no-retuning rule); (d) keep the trader's exemption from closing (Build 24 behaviour) until the owner decides. Lead recommendation: (d) now, (b) if the owner wants traders to be able to fail and recover. | OPEN | no |  | docs/directives/2026-10-30_build24_review_follow_through.md |

## Approved, no build assigned: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |

