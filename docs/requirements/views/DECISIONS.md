# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 33 |
| APPROVED | 116 |
| PROVISIONAL | 3 |
| SUPERSEDED | 2 |
| REOPENED | 0 |
| DEFERRED | 0 |

## Build 16: long-term equilibrium and validation: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| OD-17 | Owner decision: the Game Designer spec's open calls not covered by another entry: C1 the hero (spec: 'Your main character is the hero' against the confirmed 'not the chosen one'), C10 the view (top-down at an angle, three-quarter, or isometric; with DGA-D1), and Steam Deck labelling (the spec's '(web)' build; the owner said to correct the label without changing the platforms). Class progression is REC-010, ranged combat REC-009, Mote REC-002, the API 36 policy REC-003 | OPEN | no |  | docs/game-designer/SPEC_RECONCILIATION.md section 4 (REC-004, 2026-10-20) |

## Build 18: combined release (tracks A, B, C): open, reopened or provisional (5)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| Q18-11 | What pay factor and output factor should each settlement capability level give, and for which industries? (Until answered every factor is 1.0, no effect) | PROVISIONAL | no | Q18-11A, Q18-11B | docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md |
| Q18-6 | Q18-6: may abstract regions show 'two settlements develop different profiles' | PROVISIONAL | no |  | expansion18/DECISIONS_PENDING.md on wip/build18; docs/directives/2026-10-23_owner_answers_q18_4_q18_8.md |
| STONE-D1 | Stone dressing efficiency values by skill (STONE-04) and the materials rule's numbers | OPEN | yes | STONE-02, STONE-03, STONE-04, X18-STONECUT | docs/directives/2026-10-22_msw01_outstanding_issues_x18_preparation.md; expansion18/DECISIONS_PENDING.md on wip/build18 (blocked items) |
| STONE-D2 | Iron chisel wear and recipe (STONE-06) | OPEN | yes | STONE-02, STONE-06, X18-STONECUT | docs/directives/2026-10-22_msw01_outstanding_issues_x18_preparation.md; expansion18/DECISIONS_PENDING.md on wip/build18 (blocked items) |
| X18-FEES | Courier fee coefficients and the small-agreement threshold (X18-Q12, X18-Q13) | OPEN | no |  | expansion18/DESIGN.md on wip/build18 (owner questions: the fee coefficients and the small-agreement threshold need numbers) |

## Build 19: NPC Judgment System: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| X19-DECAY | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1-10 permille over 365 days; murder never decays) | PROVISIONAL | no | SJD-G | docs/directives/2026-10-23_owner_answers_x19_assault_crt12_decay.md |

## Build 20: Living Economy: open, reopened or provisional (14)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| OD-LE-02 | Owner decision (Living Economy): Market board, direct negotiation or hybrid and visibility rules | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-03 | Owner decision (Living Economy): Wages, rents and service contracts in first release | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-04 | Owner decision (Living Economy): Business founding, partnerships, ownership and inheritance | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-05 | Owner decision (Living Economy): Loan interest, collateral, default and collection rules | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-06 | Owner decision (Living Economy): Permissible manor interventions and political authority | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-07 | Owner decision (Living Economy): Restricted-use advances and business/household account separation | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-08 | Owner decision (Living Economy): Barter, rental, repair and resource substitution | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-09 | Owner decision (Living Economy): Bandit market participation and regional trading limits | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-10 | Owner decision (Living Economy): Economic rumor, memory persistence and reliability | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-11 | Owner decision (Living Economy): Speculation, hoarding and deliberate market manipulation | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-12 | Owner decision (Living Economy): Charity, kinship support and communal relief | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-13 | Owner decision (Living Economy): Contract cancellation, penalties and death of a party | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-14 | Owner decision (Living Economy): Player intervention and visibility of market decisions | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-15 | Owner decision (Living Economy): Performance and population acceptance targets | OPEN | yes |  | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |

## Build 21: Village Politics: open, reopened or provisional (9)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| Q-POL-1 | Political structure of the starting village (manor with a reeve, elected mayor, council, or a mix; what the lord retains) | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-2 | Franchise: who votes and who may stand | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-3 | Office terms, election season and by-elections (with the 8-day game year) | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-4 | Vote privacy and which totals are public | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-5 | Ties in elections | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-6 | Removal from office | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-7 | Placement and gate: politics waits for Expansion 19's live judgment, or an interim voter model behind a switch | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-8 | The constable and the law: a constable and crime records before Expansion 22; the friendly guard (X19 conflict 3) | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |
| Q-POL-9 | Taxes under an elected authority and DVW-B5's predictability | OPEN | yes |  | docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2) |

## Waiting on an owner decision for its build: open, reopened or provisional (6)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| CON-08-Q | Numerical formal-signing threshold for service contracts (owner to choose; 50 coins remains the working default) | OPEN | yes |  | docs/directives/2026-10-21_build17_consolidated_14_decisions.md |
| OD-02 | Owner decision: balance review of every provisional number | OPEN | no |  | docs/DECISIONS.md |
| OD-03 | Owner decisions: design gap assessment D1-D12 (isometric, magic, era, county) | OPEN | no |  | docs/DESIGN_GAP_ASSESSMENT.md |
| OD-04 | Owner decisions: chest and lock questions | OPEN | no |  | docs/BUILD_DECISIONS.md |
| OD-07 | Owner decision: hunting in Gather mode | OPEN | no |  | docs/HANDOFF.md |
| OD-09 | Owner decisions: GAME_DESIGN items still open (U3-U5, U13, U16-U21) | OPEN | no |  | docs/GAME_DESIGN.md |

