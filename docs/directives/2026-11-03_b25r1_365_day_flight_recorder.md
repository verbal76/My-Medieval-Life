# Owner directive, 2026-11-03 (about 15:15 EST): Build 25 Revision 1, 365-day flight recorder, migration validation and living-world proof

Saved verbatim. Register: B25R1-016. Supplements B25R1-015 (full scope); reduces nothing.

Rationale (lead's record): the owner wants evidence that the approved systems produce actual lived behaviour over many
generations, not only error-free runs. It builds on the existing flight recorder (REC-19, `mml-recorder/2`,
`docs/design/FLIGHT_RECORDER.md`; `WorldRecorder`, `recorder_analysis.gd`, `tools/flight_analyse.py`, the
`flight-recorder-campaign.yml` workflow), so no second simulation engine is created for reporting.

---

MY MEDIEVAL LIFE — BUILD 25 REVISION 1

OWNER MASTER DIRECTIVE: 365-DAY FLIGHT RECORDER, MIGRATION VALIDATION & LIVING-WORLD PROOF

Priority: Mandatory B25R1 release validation

Scope: All approved Build 25 Revision 1 systems

Execution: Coordinate with active workers, instrument during development, validate on the final integrated commit.

Record this directive word for word in the GitHub requirements register, document the rationale, update the recovery handoff, and communicate the relevant requirements to all active workers.

This directive supplements B25R1-015, the full-scope requirement. It does not replace or reduce any previously approved functionality.

---

1. Primary objective

I want a 365-simulated-day continuous-world flight recorder that proves My Medieval Life is functioning as a living society.

The simulation must demonstrate that NPCs are making decisions, moving between communities, establishing homes, developing occupations, forming families, joining and leaving bandit clans, producing goods, and surviving over multiple generations.

The flight recorder must distinguish between code that exists and gameplay that actually happens.

A simulation that completes without errors but produces no meaningful activity is not sufficient evidence.

The world uses an eight-day game year, so 365 simulated days represents approximately 45.6 game years.

This is a multigenerational validation campaign, not a short smoke test.

2. Systems to observe

Instrument and validate all approved B25R1 features, including:

Population and household systems

- Births, aging, adulthood, marriage, family formation, inheritance, and mortality
- Young adults establishing independent households
- Established adults occasionally relocating
- Children leaving households because of sustained hardship
- Orphan placement under FAM-07
- Household economic circumstances and judgment decisions

Migration

- Lawful homesteading
- Outlaw homesteading
- Migration between settlements
- Runaways seeking shelter or independence
- Bandit recruitment
- Adult bandits leaving outlaw life
- Former bandits establishing lawful homes
- Settlement abandonment and relocation

Wilderness settlements

- Land selection and occupation
- Construction and actual occupancy
- Farming and livestock
- Water and food access
- Hunting and gathering
- Storage, inventory, and consumption
- Skilled occupations
- Crafting, workshops, and trading
- Survival during offscreen simulation
- Settlement defense, raids, and mortality

Regional world

- Resident travelers making actual purchasing journeys
- Existing ambient travelers remaining functional
- Road formation through use
- Dirt-road overgrowth and restoration
- Stone-road deterioration and repair
- Material and labor consumption for paving
- Route planning and physical travel
- Landmark discovery and persistence

Interface and gameplay

- Regional map navigation and destination selection
- Gamepad navigation
- Character creation and save/load
- Wilderness interactions
- Hidden outlaw settlement discovery
- Player interaction with workshops, merchants, residents, animals, and resources

Systems that cannot be meaningfully tested through an unattended simulation must receive focused gameplay or input-driven verification.

3. Flight recorder architecture

Use the existing simulation instrumentation and logging infrastructure wherever practical.

The recorder must capture meaningful events and periodic state snapshots, not every movement frame or simulation tick.

Each event should include, where applicable:

- Simulation day and time
- Event type and category
- Persistent NPC ID
- NPC name, age, and life stage
- Household ID
- Origin and destination
- Settlement or wilderness location ID
- Current faction and legal standing
- Relevant needs and economic circumstances
- Decision trigger
- Judgment factors and outcome
- Actual action taken
- Success, failure, rejection, or abandonment
- Reason for the outcome
- Resource or money transfers
- Related NPC, household, settlement, and clan IDs

Use stable IDs so events can be reconstructed into complete individual histories.

The recorder must observe both onscreen and offscreen simulation.

Do not create a second independent simulation engine merely for reporting.

4. Homesteading migration lifecycle

Record each stage separately:

1. An NPC reaches a meaningful life transition.
2. Existing judgment evaluates available opportunities.
3. The NPC chooses or rejects homesteading.
4. A viable wilderness site is evaluated.
5. The NPC physically travels there.
6. Land is claimed or occupied.
7. Required resources are obtained.
8. Shelter and infrastructure are constructed.
9. The NPC establishes actual residence.
10. Food, water, employment, and household needs are sustained.
11. The household continues through subsequent years.
12. Family changes, inheritance, abandonment, or death occur naturally.

Report the number of eligible decisions, attempted moves, completed moves, failed attempts, and surviving homesteads.

Do not count an intention or land claim as a completed homestead.

Track established-adult relocation separately from young-adult household formation.

The approved young-adult population safeguard remains approximately 2% or less of eligible household formations over five game years, not 2% of all residents.

5. Youth runaways and hardship

Record:

- Persistent household hunger and financial hardship
- Relevant family circumstances
- Accumulated hardship duration
- Age and maturity
- Available assistance
- Judgment evaluation
- Decision and actual outcome

Possible outcomes include staying home, seeking help, finding work, relocating, surviving independently, or approaching an outlaw community.

Runaway evaluations occur at meaningful hardship thresholds or life events, at most once per season unless a significant new event warrants reevaluation.

The normal minimum age is 12. Younger children may leave only under severe circumstances.

Preserve existing orphan-placement rules.

The flight recorder must distinguish between hardship that legitimately produces a runaway and hardship where the NPC reasonably remains home.

6. Bandit recruitment and population sustainability

Track recruitment by source:

- Unplaced orphans
- Youth runaways
- Displaced adults
- Criminal fugitives
- Voluntary adult recruits
- Existing social and family relationships
- Children raised in outlaw communities who later choose membership

For each recruit, record:

1. Original identity and household.
2. Circumstances leading to recruitment.
3. Decision to seek outlaw life.
4. Physical travel or contact with a clan.
5. Clan acceptance or rejection.
6. Actual membership and residence changes.
7. Occupation, training, and economic contributions.
8. Subsequent life events, including departure or death.

Bandit population must be reconciled through births, recruitment, deaths, and departures.

Do not create replacement bandits merely to maintain a target population.

The objective is a sustainable human recruitment stream, not an artificially fixed number of enemies.

7. Adult bandit departures and reintegration

Observe adult bandits who decide to leave outlaw life.

Track:

- Decision trigger and judgment
- Departure from clan membership
- Physical relocation
- Retained possessions and skills
- Retained criminal and reputation history
- New occupation or household
- Lawful homesteading where applicable
- Marriage, family, and subsequent life events

A faction change must never create a replacement NPC or erase their history.

8. Shared lawful and outlaw homesteading

The same wilderness settlement foundation must support lawful and outlaw communities.

Observe actual settlement development:

- Construction
- Occupancy
- Household formation
- Farming and livestock
- Skilled employment
- Workshops and crafting
- Resource gathering
- Storage and consumption
- Trade and money transfers
- Hidden location discovery
- Defense and raiding
- Settlement expansion, decline, or abandonment

Track settlement ownership and affiliation changes without recreating buildings or residents.

A bandit community must be capable of supporting itself through productive work rather than depending exclusively on raids.

9. Economic flight recorder

Record real economic activity:

- Raw material extraction
- Farming yields and food consumption
- Livestock births, deaths, and transfers
- Crafting inputs and finished outputs
- Skill progression through actual work
- Purchases and sales
- Employment and wages
- Construction materials and labor
- Road paving and repair
- Bandit raids and transferred goods
- Inventory and money ownership changes

All economic events must reconcile with the existing production, consumption, and conservation rules.

Distinguish legitimate production and consumption from unexplained creation or destruction.

Pay particular attention to wilderness food and water access, farming outside villages, offscreen danger, and repeated refusal of legitimate resource sales.

These are approved implementation requirements, not optional enhancements.

10. Continuous population measurements

Capture periodic snapshots sufficient to show long-term trends.

At minimum measure:

- Total world population
- Population by settlement
- Wilderness population
- Lawful and outlaw populations
- Age and life-stage distribution
- Births and deaths
- Household formation and dissolution
- Homestead migration by source and outcome
- Runaway decisions and outcomes
- Bandit recruitment by source
- Bandit deaths and departures
- Former bandit reintegration
- Active and abandoned homesteads
- Occupations and skill development
- Food production and shortages
- Settlement economic activity
- Clan population and survival

Use correct denominators when calculating migration rates.

Monitor village stability and identify demographic collapse, runaway migration loops, or implausible population growth.

Do not assume that a stable total population means the underlying systems are functioning properly.

11. Required individual NPC life histories

This is a mandatory reporting deliverable.

The flight recorder must reconstruct complete, chronological histories for representative NPCs.

Include actual examples where observed of:

A. Lawful homesteader

A young adult leaves a village, selects wilderness land, builds a home, establishes a livelihood, and continues living there.

Track later family formation, children, work, property, and mortality where these occur.

B. Established-adult homesteader

An established resident experiences a meaningful life change, decides to relocate, and establishes a new household without losing their history or obligations.

C. Youth runaway

A young person experiences sustained hardship, considers alternatives, leaves home, and follows a believable survival path.

D. Bandit recruit

A persistent NPC leaves ordinary society, encounters an outlaw clan, becomes a member, and participates in its economy.

E. Skilled outlaw

A bandit develops an occupation, gathers or purchases materials, produces actual goods, and contributes to the settlement.

F. Former bandit

An adult leaves outlaw life, relocates, and attempts to reintegrate into ordinary society while retaining relevant history.

G. Multigenerational household

Follow a household through births, adulthood, new households, inheritance, and deaths.

For every history, show the NPC's persistent ID, event timeline, locations, decisions, economic changes, and final status.

Do not fabricate an example when no matching organic event occurred. Mark it as unobserved and provide separate targeted-scenario evidence.

12. Organic activity versus targeted validation

The main 365-day campaign must use the normal approved game rules and population settings.

Do not force NPCs to migrate, join bandits, or establish homesteads merely to generate attractive metrics.

Do not artificially raise migration or recruitment probabilities for the organic campaign.

Classify each feature as:

- No eligible opportunity occurred
- Eligible opportunity occurred but judgment rejected it
- Decision made but action failed
- Action partially completed
- Action successfully completed
- Activity continued sustainably

If a rare feature does not naturally occur during 365 days, run a separate deterministic targeted scenario with explicitly documented starting conditions.

Clearly separate targeted evidence from organic results.

A targeted scenario proves a mechanic can function; it does not prove the mechanic occurs at a healthy natural frequency.

Report both findings.

13. Determinism, conservation, and persistence

Verify:

- Same seed and configuration produce identical event streams and fingerprints.
- Save/load preserves decisions, relationships, ownership, and migration state.
- Every NPC is accounted for.
- No duplicate people or unexplained disappearances occur.
- Money and inventories reconcile.
- Production and consumption follow legitimate game rules.
- Livestock and equipment ownership remain consistent.
- Household and faction transitions preserve identities.
- Offscreen world simulation produces valid outcomes.
- No impossible family, settlement, or ownership states appear.
- No infinite migration loops occur.
- No uncontrolled village depopulation occurs.

Use checkpointed save/load verification where appropriate.

A deterministic failure must be diagnosed, not hidden through loose tolerances or excluded events.

14. Reports and visualizations

Generate retained GitHub Actions artifacts containing:

A. Executive report

Summarize what actually occurred during the 365 simulated days.

B. Complete migration ledger

Every recorded NPC migration, origin, destination, reason, and outcome.

C. Bandit population ledger

Recruitment, births, deaths, departures, and population reconciliation.

D. Homestead ledger

Settlement creation, residents, construction, production, survival, and abandonment.

E. Economic ledger

Production, purchases, sales, wages, crafting, livestock, raids, and resource transfers.

F. Individual life histories

Complete representative NPC event timelines, with stable IDs and supporting records.

G. Charts

Prefer line and scatter charts showing population, migration, clan membership, household growth, economic activity, and settlement survival over time.

Avoid bar charts unless they are genuinely the clearest representation.

H. Exception report

Missing activity, failed attempts, conservation violations, demographic instability, broken journeys, abandoned work, and unexpected simulation behavior.

I. Evidence index

Exact source SHA, seed, configuration, test names, CI run identifiers, artifact locations, fingerprints, and validation results.

All reports must distinguish observed facts from interpretations.

15. Execution efficiency

Coordinate instrumentation with active development workers.

Do not interrupt unrelated implementation.

Use focused tests for individual features before running the full campaign.

Run the 365-day campaign against the final integrated candidate after relevant systems are complete.

Reuse valid green CI evidence for the exact source commit.

Do not rerun expensive campaigns solely for reassurance.

If the final source changes in a way that affects simulation behavior, identify the affected evidence and rerun only what is necessary.

Preserve the completed campaign artifacts for future comparison and recovery.

16. Release acceptance criteria

Build 25 Revision 1 is not fully validated until:

1. Every approved B25R1 feature is implemented and enabled.
2. Focused functional and gameplay tests pass.
3. The 365-day flight recorder completes.
4. Actual homesteading and bandit migration behavior is demonstrated.
5. Rare unobserved behaviors have clearly labeled targeted validation.
6. Population accounting and conservation pass.
7. Deterministic replay and save/load pass.
8. Wilderness settlements operate during offscreen simulation.
9. Individual NPC life histories can be reconstructed.
10. Village and bandit population trends are reviewed for sustainability.
11. The final reports and artifacts are retained in GitHub.
12. The private Revision 1 packages correspond to the validated release candidate.

The original Build 25 private draft remains untouched as the rollback.

Do not reduce the approved scope or disable unfinished functionality to obtain passing tests.

If a genuine architectural obstacle arises, report the obstacle, available solutions, recommended approach, and consequences to the owner. Continue unrelated work while awaiting the decision.

---

FINAL OWNER INSTRUCTION

I want proof that My Medieval Life is actually living.

Show me who leaves home, why they leave, where they travel, what they build, how they earn their living, who they marry, what happens to their children, and how their lives eventually end.

Show me the same for the bandits: where recruits come from, how clans survive, what they produce, what they steal, how their communities develop, and who eventually leaves outlaw life.

Do not give me only pass/fail totals.

Give me the migration records, population trends, economic evidence, and complete individual life stories that prove these systems are operating together over 365 simulated days.

Record this directive, coordinate the instrumentation, continue the approved implementation, and execute the campaign when the final integrated candidate is ready.

The goal is not merely a stable simulation. The goal is a believable, measurable, persistent living world.
