# Owner decisions

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

The decision register is the `decision` records of the register. A recommendation is never an approval; PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when evidence shows unintended consequences (SCHEMA.md, change control).

| Disposition | Count |
|---|---|
| OPEN | 26 |
| APPROVED | 286 |
| PROVISIONAL | 2 |
| SUPERSEDED | 3 |
| REOPENED | 0 |
| DEFERRED | 5 |

## Build 20: Living Economy: open, reopened or provisional (6)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| B25-ECON-P1 | Business founding requires the trade's benches to be full and busy (Ventures.refusal, skilled_place busy_share 0.35); in seed 1 the founding trades' benches were 2-20% busy all 120 days, so every one of 172 weekly looks stopped there. Options: A keep the rule (businesses form when demand exists); B let a founder weigh independence even with idle benches (the judgment weighing decides); C a lower busy threshold for founding only. Recommendation: A, and act on demand (P2-P4) rather than the gate. Evidence: docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md on the Build 25 source (d6ab686). | OPEN | no |  | docs/directives/2026-11-02_overnight_autonomous_development_directive.md |
| B25-ECON-P2 | Coinless adults cannot take open miner or woodcutter places because those jobs need a tool and the manor's tool help covers only workers already in the trade (all 10 jobless at day 120 came of age in the run and hold median 0 coins). Options: A keep; B the household buys a member's first work tool from its own purse (existing purchase rules); C the manor advances the tool against wages; D tool rental outside the Living Economy. Recommendation: B. Evidence: docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md on the Build 25 source (d6ab686). | OPEN | no |  | docs/directives/2026-11-02_overnight_autonomous_development_directive.md |
| B25-ECON-P3 | Retired villagers keep trade stock forever (day 120: 68 iron ore, 47 coal, 24 iron bars, 8 pickaxes, 7 axes held by elders while the working smith held nothing). Options: A keep; B elders and adults between jobs sell their goods through the existing sell rule; C the stock passes to the trade's successor as tools already do. Recommendation: B. Evidence: docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md on the Build 25 source (d6ab686). | OPEN | no |  | docs/directives/2026-11-02_overnight_autonomous_development_directive.md |
| B25-ECON-P4 | Ore imports stall: Garton's quarry stock rose 63 to 175 but its trader had no coins to buy it, so 0 iron ore came to the village in 120 days (2 in a year for seed 2). Options: A keep as an outcome; B the trader carries ore on consignment (paid on sale); C smiths buy from the quarry directly. Recommendation: decide after the final year-long runs; leaning B. Evidence: docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md on the Build 25 source (d6ab686). | OPEN | no |  | docs/directives/2026-11-02_overnight_autonomous_development_directive.md |
| B25-ECON-P5 | Village land (fields, trees, game, ore) is fixed while population roughly triples in a year, so unemployment rises with population. Should fields grow with population? Recommendation: no change on present evidence. Evidence: docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md on the Build 25 source (d6ab686). | OPEN | no |  | docs/directives/2026-11-02_overnight_autonomous_development_directive.md |
| CHAPEL-GIVE-14-Q | With the 14-day hardship line now governing chapel food alms, households offer wheat to the chapel only above 14 days of their own food (was 6, goods_keep_days), so food given as alms is not offered back. Accept this change to the giving rule? Options: A accept (recommended: consistent with the 14-day line, prevents give-and-take, keeps donations voluntary and from comfortable households); B keep the 6-day offering line (some households would both receive alms and offer wheat). Implemented provisionally as A at 8b203c5. | OPEN | no |  | docs/directives/2026-11-02_chapel_economic_purpose_correction.md |

## Build 21: Village Politics: open, reopened or provisional (1)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| P21-OFFICES-Q1 | Political offices other than the mayor: their terms, succession, dismissal and vacancy rules (the mayor's rule is not extended to them automatically) | OPEN | no |  | docs/directives/2026-10-31_doc_recon_review_decisions.md |

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

## Approved, no build assigned: open, reopened or provisional (6)

| ID | Question | Disposition | Blocks implementation | Affects | Source |
|---|---|---|---|---|---|
| BRANCH-POL-Q1 | Records line and code line: keep wip/requirements-control (records, lead-written) separate from wip/expansion20 (code), with notices on the code line's copies (recommended); or authorize bringing the records into wip/expansion20 as one reviewed change (files only, not the old ancestry)? | OPEN | no |  | docs/decisions/BRANCH-POL-01.md |
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | PROVISIONAL | no |  | docs/directives/2026-10-23_id_d2_succession_decisions.md |
| JUICE-JD2 | Day and night: should the picture darken at night (how dark at midnight; interiors; underground already dark)? | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D2 (origin/wip/juice-assessment bebf1f3) |
| JUICE-JD3 | Villager chatter: how often may villagers show what they are doing in bubbles (OWN-19 extension)? | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D3 |
| JUICE-JD4 | Screen shake and haptics: allowed at all, on which events, and default on or off? | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D4 |
| JUICE-JD5 | Notifications: which village notes the player sees in the corner log by default, and whether a filter exists. | OPEN | no |  | the juice assessment PRELIMINARY_ASSESSMENT.md (only on branch wip/juice-assessment) section 6 D5 |

