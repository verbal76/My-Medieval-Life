# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 23 |
| APPROVED | 245 |
| PROVISIONAL | 3 |
| SUPERSEDED | 3 |
| REOPENED | 0 |
| DEFERRED | 5 |

## Build 20: Living Economy: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| ARMOR-CATALOG-D1 | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials option A or B for Build 22, the example values (the rest by the same rules), and whether the cloth headgear is included (docs/design/ARMOUR_CATALOGUE_PROPOSAL.md) | PROVISIONAL | no | ARMOR-CATALOG-01, ARMOR-MATERIALS-01 | docs/design/ARMOUR_CATALOGUE_PROPOSAL.md |

## Build 25: Weather, Seasons and Disasters: open, reopened or provisional (5)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| E25-OD-03 | Wells for bucket lines away from the river (packet recommendation: one or two wells as public works the reeve can build) | OPEN | no | WEATHER-01 | docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md s.6; docs/directives/2026-10-23_dynamic_weather_idea.md |
| E25-OD-06 | May the reeve keep a disaster reserve in the treasury? (recommendation: yes, inside the existing reserve rule, no new money) | OPEN | no | WEATHER-01 | docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md s.6; docs/directives/2026-10-23_dynamic_weather_idea.md |
| E25-OD-07 | When to build Expansion 25 relative to Expansions 20-24 | PROVISIONAL | no | WEATHER-01 | docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md s.6; docs/directives/2026-10-23_dynamic_weather_idea.md |
| E25-OD-08 | How long is a swept-away person missing? (recommendation: 1 to 3 game days by a seeded draw) | OPEN | no | WEATHER-01 | docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md s.6; docs/directives/2026-10-23_dynamic_weather_idea.md |
| E25-OD-09 | Can a building be insured or protected (stone versus wood)? (recommendation: stone resists fire and wind better; no insurance in this expansion) | OPEN | no | WEATHER-01 | docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md s.6; docs/directives/2026-10-23_dynamic_weather_idea.md |

## Build 26: Creatures and Heroes: open, reopened or provisional (9)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| E26-OD-01 | Foxes: pets only, or also companions? (recommendation: companions too; only their pen use is pets-only) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-02 | Monster respawn (recommendation: skeletons 3 days as approved, spiders alike; a killed boss not back for a game year, some never) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-03 | How often a monster attacks the village (recommendation: about once in several game years, never more than one at a time) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-04 | Bounties when the treasury is empty (recommendation: no bounty without the coins; villagers may pool coins) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-05 | Bounty prices (recommendation: set by the reeve within an owner-approved band, proposal 20-60 coins monsters, 150-400 bosses) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-06 | Monster goods recipes (recommendation: one special item per boss plus bones and rusty gear from skeletons) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-07 | Companion combat numbers (recommendation: wolf about a wild wolf, fox weaker but quicker; heal with rest and food) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-08 | Can villagers' pets or guard dogs fight in village defence? (recommendation: guard dogs join the guards' line) | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |
| E26-OD-09 | When to build Expansion 26, and may phases 26-A..C and 26-F start before Expansion 25? | OPEN | no | MON-01, PET-01 | docs/design/EXPANSION26_CREATURES_AND_HEROES.md s.5 |

## Future backlog (Build 20 or later, not assigned): open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| X19-SWITCHES-D1 | Enable in normal play the integrated-but-off Build 19 recovery features: R5 aspirations (judgment.json aspiration.enabled, decision.integration.job_choice; WDR-011-C) and the R2 judgment-weighted witness report hook (decision.integration.report; SJD-F)? | OPEN | no |  | game/data/judgment.json@origin/wip/expansion20 ad281dc (_aspiration_note: 'OFF (enabled false) until validation and owner review'); R5_ASPIRATIONS_DESIGN.md (expansion20 notes, on wip/expansion20)@X20; merge 9b90e05 |

## Approved, no build assigned: open, reopened or provisional (10)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| FARM-YIELD-D1 | Shared farming model: which wheat yield per cell, and may shared_manor_farming (FSE-12, FARM-06) and seasonal_village_farming (FSE-13) be switched on in the normal game? | OPEN | no |  | docs/directives/2026-10-21_fse12_fse13_farming_decision.md: 'I am not approving the existing 3-wheat-per-cell yield or selecting a replacement yield yet. Keep both FSE-12 and FSE-13 switches off ... Report the comparison results and your proposed value for my approval before enabling either switch globally.' Comparison: docs/design/FARM08_YIELD_COMPARISON.md ('Status: awaiting the owner's approval'). |
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |
| JUICE-J1 | May phase J1 (quick wins: notification split, coin tick, prompt pulse, hurt frames, 'Reduce effects' setting, unused fx_dust; one pooled effects helper) be implemented, and in which build? | OPEN | no |  | docs/directives/2026-10-22_game_juice_preliminary_assessment.md ('Report the top ten improvements ... and wait for approval'); the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 7 |
| JUICE-JD2 | Day and night: should the picture darken at night (how dark at midnight; interiors; underground already dark)? | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D2 (origin/wip/juice-assessment bebf1f3) |
| JUICE-JD3 | Villager chatter: how often may villagers show what they are doing in bubbles (OWN-19 extension)? | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D3 |
| JUICE-JD4 | Screen shake and haptics: allowed at all, on which events, and default on or off? | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D4 |
| JUICE-JD5 | Notifications: which village notes the player sees in the corner log by default, and whether a filter exists. | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D5 |
| X20-ACTIVATION-AUTHORITY | Does X20-RESUME's automatic Living Economy activation on objective readiness (2026-10-30) still stand after the 2026-10-31 instructions to keep the economy disabled by default and the Build 25 freeze, or does activation now need explicit owner approval? | OPEN | no |  | 2026-10-30_master_development_resumption.md s.4 vs 2026-10-31_x20_merged_validation_decisions.md and 2026-10-31_sjdh_decisions_le05_authorization.md |
| X20-REMAINING-PLACEMENT | Where does the remaining Expansion 20 scope go relative to the Build 25 freeze (LE-07, EMP-PERM-01, LE-05 remainder, economy activation, SJD-H review): finished before the freeze, in Build 26, or carried past it? | OPEN | no |  | docs/directives/2026-10-27_complete_expansion20_first.md (X20-COMPLETE) vs docs/directives/2026-10-31_documentation_reconciliation.md (BUILD-SEQ-25-27) |
| X20-SERVICES-SCOPE | Does X20-SCOPE's 'negotiated wages and service contracts behind their switches (OD-LE-03/D02)' include the approved service-contract records CON-03..CON-08 (CON02-S-1..6 answers), or do they stay unscheduled? | OPEN | no |  | X20-SCOPE owner_answer; CON-03..08 target 'owner decision'; LE04_IMPLEMENTATION.md s.4 (market.services empty) |

