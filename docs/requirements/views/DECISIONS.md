# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 36 |
| APPROVED | 187 |
| PROVISIONAL | 2 |
| SUPERSEDED | 2 |
| REOPENED | 0 |
| DEFERRED | 1 |

## Build 16: long-term equilibrium and validation: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| OD-17 | Owner decision: the Game Designer spec's open calls not covered by another entry: C1 the hero (spec: 'Your main character is the hero' against the confirmed 'not the chosen one'), C10 the view (top-down at an angle, three-quarter, or isometric; with DGA-D1), and Steam Deck labelling (the spec's '(web)' build; the owner said to correct the label without changing the platforms). Class progression is REC-010, ranged combat REC-009, Mote REC-002, the API 36 policy REC-003 | OPEN | no |  | docs/game-designer/SPEC_RECONCILIATION.md section 4 (REC-004, 2026-10-20) |

## Build 18: combined release (tracks A, B, C): open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| Q18-11 | What pay factor and output factor should each settlement capability level give, and for which industries? (Until answered every factor is 1.0, no effect) | PROVISIONAL | no | Q18-11A, Q18-11B | docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md |

## Build 19: NPC Judgment System: open, reopened or provisional (2)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| SIM-F2 | Recorder finding F2: a stonecutter re-chose a failing iron-chisel purchase 328 times in one day (day 2, seed 1), losing a working day; same re-decision family as REC-F1. Approve a narrow fix? | OPEN | no |  | docs/directives/2026-10-23_simulation_first_diagnostics.md |
| SIM-F3 | Recorder finding F3: bandits stalking at night leave their plan empty, so the brain re-decides every tick (400+ empty decisions a day each); behaviour works through the chase target. Approve giving the stalk a lasting plan step (performance fix, no behaviour change intended)? | OPEN | no |  | docs/directives/2026-10-23_simulation_first_diagnostics.md |

## Build 20: Living Economy: open, reopened or provisional (15)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ARMOR-CATALOG-D1 | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials option A or B for Build 22, the example values (the rest by the same rules), and whether the cloth headgear is included (docs/design/ARMOUR_CATALOGUE_PROPOSAL.md) | PROVISIONAL | no | ARMOR-CATALOG-01, ARMOR-MATERIALS-01 | docs/design/ARMOUR_CATALOGUE_PROPOSAL.md |
| OD-LE-02B | Offer visibility: who can see an offer (in person at stalls and meetings, by word of mouth, a notice board), the remaining part of OD-LE-02 | OPEN | no |  | docs/directives/2026-10-23_expansions_19_21_consolidated_design.md |
| OD-LE-03 | Owner decision (Living Economy): Wages, rents and service contracts in first release | OPEN | yes | ECON-P3.4 | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-04 | Owner decision (Living Economy): Business founding, partnerships, ownership and inheritance | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-05B | Interest and lending: whether loans carry interest or fees, who may lend money, and collection procedures (the remaining part of OD-LE-05) | OPEN | no |  | docs/directives/2026-10-23_expansions_19_21_consolidated_design.md |
| OD-LE-06 | Owner decision (Living Economy): Permissible manor interventions and political authority | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-07 | Owner decision (Living Economy): Restricted-use advances and business/household account separation | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-08 | Owner decision (Living Economy): Barter, rental, repair and resource substitution | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-09 | Owner decision (Living Economy): Bandit market participation and regional trading limits | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-10 | Owner decision (Living Economy): Economic rumor, memory persistence and reliability | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-11 | Owner decision (Living Economy): Speculation, hoarding and deliberate market manipulation | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-12 | Owner decision (Living Economy): Charity, kinship support and communal relief | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-13B | Death of a party to a contract: does the contract end, pass to the heir or the household, or go to the estate (the remaining part of OD-LE-13) | OPEN | no |  | docs/directives/2026-10-23_expansions_19_21_consolidated_design.md |
| OD-LE-14 | Owner decision (Living Economy): Player intervention and visibility of market decisions | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-15 | Owner decision (Living Economy): Performance and population acceptance targets | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |

## Build 21: Village Politics: open, reopened or provisional (9)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| P21-RESIDENCY | How long must an adult live in a settlement to count as an established resident (to vote and stand for mayor)? | OPEN | no |  | docs/directives/2026-10-23_expansions_19_21_consolidated_design.md |
| P21-STRUCTURE | Beyond the elected mayor: councils and their powers, the manor or a lord's authority over the village, regional government, and whether smaller settlements have simpler government | OPEN | no |  | docs/directives/2026-10-23_expansions_19_21_consolidated_design.md |
| Q-POL-1 | Political structure of the starting village (manor with a reeve, elected mayor, council, or a mix; what the lord retains) | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-4 | Vote privacy and which totals are public | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-5 | Ties in elections | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-6 | Removal from office | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-7 | Placement and gate: politics waits for Expansion 19's live judgment, or an interim voter model behind a switch | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-8 | The constable and the law: a constable and crime records before Expansion 22; the friendly guard (X19 conflict 3) | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-9 | Taxes under an elected authority and DVW-B5's predictability | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |

## Build 22: Settlement Advancement Phase 2: open, reopened or provisional (3)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| E22-OD-03 | Knowledge persistence: how industrial knowledge passes on (teaching, apprenticeship, written records) or is lost when skilled people die or leave; Build 18 keeps it only in living people | OPEN | no |  | docs/directives/2026-10-23_expansions_22_23_kickoff.md |
| E22-OD-04 | Regional trade and transport: do traders' trips take real travel time, carry limited loads and risk loss on routes (replacing the instant six-day road trade), and do settlements trade with each other beyond the village | OPEN | no |  | docs/directives/2026-10-23_expansions_22_23_kickoff.md |
| E22-OD-05 | Population across the region: should off-map settlements get housing and land that limit growth (REG-DEMO-D1 left this to future systems), and may whole settlements be abandoned | OPEN | no |  | docs/directives/2026-10-23_expansions_22_23_kickoff.md |

## Build 23: Bandit Factions and Criminal Careers: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| E23-OD-01 | Bandit factions: territory and jurisdiction, how many factions may exist and how they form, how leadership changes, and whether crimes act only on real inventories reached by real travel | OPEN | no |  | docs/directives/2026-10-23_expansions_22_23_kickoff.md |

## Approved, no build assigned: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | OPEN | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |

## Waiting on an owner decision for its build: open, reopened or provisional (5)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| OD-02 | Owner decision: balance review of every provisional number | OPEN | no |  | docs/DECISIONS.md |
| OD-03 | Owner decisions: design gap assessment D1-D12 (isometric, magic, era, county) | OPEN | no |  | docs/DESIGN_GAP_ASSESSMENT.md |
| OD-04 | Owner decisions: chest and lock questions | OPEN | no |  | docs/BUILD_DECISIONS.md |
| OD-07 | Owner decision: hunting in Gather mode | OPEN | no |  | docs/HANDOFF.md |
| OD-09 | Owner decisions: GAME_DESIGN items still open (U3-U5, U13, U16-U21) | OPEN | no |  | docs/GAME_DESIGN.md |

