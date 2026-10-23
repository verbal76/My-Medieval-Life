# Owner directive, 2026-10-23: Build 19 Comprehensive World Simulation Flight Recorder

Saved verbatim. The owner states it supersedes all earlier prompts concerning the simulation recorder.

---

MY MEDIEVAL LIFE — MASTER DEVELOPMENT DIRECTIVE

Build 19: Comprehensive World Simulation Flight Recorder

Full-Scope Interaction Logging, Causal Mapping, Forensic Diagnostics, and Excel Export

OWNER DIRECTIVE — SINGLE CONSOLIDATED SPECIFICATION

This document supersedes all earlier prompts concerning the simulation recorder. Treat it as one unified requirement, not as an additional clarification.

1. Purpose and design philosophy

My Medieval Life is intended to be a living, autonomous medieval world that exists and functions independently of the player.

The player is not the center of the simulation.

The player may spend an entire game day walking around, observing villagers, sitting beside a river, or doing absolutely nothing. During that time, the inhabitants must continue working, trading, consuming resources, making decisions, building relationships, migrating, governing, committing crimes, and living their own lives.

The purpose of this diagnostic system is to make that entire simulation observable and auditable.

We are developing a comprehensive simulation flight recorder, not a conventional player activity log, analytics dashboard, or simple event counter.

The recorder must document what happens throughout the active village, how it happens, why decisions are made, what systems participate, what changes as a result, and how those changes influence subsequent events.

The ultimate objective is to export comprehensive diagnostic data that can be examined independently, including by ChatGPT, to identify broken interactions, systemic imbalances, unintended behavior, contradictory decisions, missing consequences, and failures that conventional automated tests might not detect.

This is intended to become permanent development infrastructure supporting Expansions 19–23 and future systems.

Include this recorder in the Build 19 development scope.

It is not a separate gameplay expansion.

---

2. Recording scope: the entire simulated world

2.1 Full active-village coverage

Record all meaningful simulation activity occurring within the player's currently active settlement and its simulated surrounding area.

This includes every simulated:

- Villager and player character.
- Household and family.
- Business, workplace, and employer.
- Farm, mine, workshop, and production facility.
- Merchant, trader, and transport operation.
- Government institution and civic official.
- Guard, criminal, and faction.
- Resource source, inventory, and economic participant.
- Relevant settlement-level process.

Recording must continue regardless of player participation.

If the player does nothing for 100 simulated days, the recorder must still document the village's activity throughout those 100 days.

2.2 Record all interaction categories

Capture NPC-to-NPC, NPC-to-player, NPC-to-business, business-to-business, household-to-household, NPC-to-government, government-to-business, settlement-to-settlement, and all other supported interaction types.

Record autonomous activities that do not require a second participant, including:

- Working and producing goods.
- Gathering, mining, harvesting, and hunting.
- Consuming food and other resources.
- Resting, traveling, and changing locations.
- Managing inventories and property.
- Evaluating needs and opportunities.
- Seeking employment, employees, customers, or suppliers.
- Making social, economic, or civic decisions.
- Forming or ending relationships.
- Entering, fulfilling, or breaking obligations.
- Responding to threats, scarcity, and environmental conditions.

Record unsuccessful attempts, refusals, interruptions, and abandoned actions as well as successful outcomes.

2.3 Distant and abstract simulation

Expansion 22 introduces a hybrid detailed/abstract simulation architecture.

The recorder must support both levels without inventing events.

For detailed simulation, capture actual individual interactions and state transitions.

For abstract simulation, capture every executed aggregate transition, its inputs, outputs, affected entities, and causal references available from the actual implementation.

Do not claim individual NPC actions occurred if the engine only simulated an aggregate settlement outcome.

Record transitions between detailed and abstract simulation and verify that identity, ownership, resources, obligations, and history remain consistent.

---

3. Complete interaction records

Every meaningful interaction must receive a unique interaction ID.

Every event must receive a unique event ID.

Every participating entity must be referenced using its stable authoritative identity.

For each interaction, capture all applicable information actually available during execution.

3.1 Identification and context

- Interaction ID.
- Event ID.
- Parent interaction or event ID.
- Causal correlation ID.
- Game day and game time.
- Simulation tick or sequence number.
- World seed.
- Settlement and region.
- Location or coordinates when relevant.
- Initiating actor.
- All participants and their roles.
- Source system and subsystem.
- Interaction category and subtype.
- Feature flags and relevant simulation mode.
- Applicable game rules or rule identifiers.

3.2 Triggers and motivations

Record what caused the interaction.

Examples include hunger, lack of resources, employment needs, economic opportunity, social desire, contractual obligation, criminal intent, political ambition, external threat, or a prior event.

Capture the actual trigger, relevant needs, constraints, and available information.

Do not invent motivations that were never evaluated by the simulation.

3.3 Decision-making

For decisions, record:

- Actual alternatives considered.
- Alternatives rejected and their recorded rejection reasons.
- Decision factors actually evaluated.
- Need and priority values.
- Personality influences.
- Relationship and reputation influences.
- Trust, hostility, and familiarity.
- Economic factors.
- Scarcity and availability.
- Family and household considerations.
- Legal and political considerations.
- Known information and beliefs.
- Applicable thresholds and modifiers.
- Deterministic tie-breaking or random selection inputs, where applicable.
- Selected action.
- Recorded reason or scoring basis for selection.

Do not create fictional explanations after the decision.

Instrument the actual decision-making execution path.

Where an alternative or factor is not evaluated by the engine, mark it as not evaluated rather than inventing a value.

3.4 Execution and outcome

Record:

- Intended action.
- Actual attempted action.
- Preconditions.
- Preconditions passed or failed.
- Participants accepting or refusing.
- Negotiation and counteroffers.
- Final agreement or disagreement.
- Execution success or failure.
- Interruptions.
- Applicable failure reasons.
- Actual effects.
- Subsequent events triggered.

---

4. Complete state-change tracking

The recorder must capture the authoritative changes caused by interactions.

Each state change should reference the originating event or interaction.

Record relevant before-and-after values for:

- Inventory quantities.
- Currency balances.
- Resource deposits.
- Ownership.
- Employment.
- Production.
- Consumption.
- Prices and transaction terms.
- Contracts and reservations.
- Debt and collateral.
- Relationships and judgment ledgers.
- Personality or experience changes.
- Reputation.
- Health, hunger, and other needs.
- Household membership.
- Residence and settlement membership.
- Migration.
- Civic office and authority.
- Treasury balances and taxes.
- Crime records and legal consequences.
- Faction membership and resources.
- Other persistent gameplay state.

Use typed state-change records instead of forcing unrelated properties into one oversized row.

Every change must identify the entity, property, prior value, new value, change amount where applicable, and authoritative source.

Capture sufficient information to reconstruct the change without relying on guessed explanations.

---

5. Causal interaction mapping

This is a critical requirement.

We must be able to determine not only what happened, but how it happened and what part each interaction played in the resulting outcome.

Create a linked causal event structure.

The system must support:

1. Tracing an outcome backward to recorded contributing events.
2. Tracing an action forward to its recorded consequences.
3. Identifying every system that participated in an interaction.
4. Identifying which state changes were produced by which actions.
5. Identifying all interactions involving a particular person, household, business, settlement, or resource.
6. Following multi-day sequences of consequences.
7. Distinguishing direct causation, recorded dependencies, and mere chronological correlation.

Example

A bakery closes.

The recorder should allow us to investigate whether:

- A merchant failed to deliver iron.
- A mill could not obtain replacement equipment.
- Flour production decreased.
- The bakery could not purchase flour.
- The bakery lost customers or income.
- Its inventory or currency became insufficient.
- The owner chose to close the business.

If the actual recorded sequence supports that explanation, we can identify a legitimate emergent economic consequence.

If the bakery closed because inventory disappeared, a contract was double-reserved, or money was incorrectly deducted, we can identify a defect.

The recorder must preserve the evidence necessary to distinguish those situations.

Do not create artificial causal links simply because events happened near each other in time.

---

6. Cross-expansion integration

The recorder must use one common diagnostic infrastructure across the game.

It must not create competing gameplay systems, independent economic ledgers, alternative relationship engines, or duplicate authoritative state.

Build 18 baseline

Instrument existing functionality, including:

- Villager activities.
- Households.
- Employment.
- Production and consumption.
- Resource extraction.
- Trade.
- Contracts.
- Migration.
- Settlements and couriers.
- Worker experience.
- Existing legal and relationship behavior.
- Player interactions.
- Save/load and succession events.

Preserve existing Build 18 behavior.

Expansion 19 — Judgment and relationships

Capture subjective judgment events, observers, Good/Bad ledger changes, gossip transmission, information discovery, social decision factors, relationship changes, and consequences.

Record what each character actually knows rather than using omniscient world information.

Expansion 20 — Living economy

Capture production, purchases, negotiations, contracts, debt, collateral, prices, ownership, reservations, supply chains, shortages, and conservation checks.

Expansion 21 — Politics

Capture candidacy, elections, voter decisions, civic appointments, taxation, budgets, treasury transactions, guard decisions, law enforcement, and political consequences.

Expansion 22 — Settlement advancement

Capture regional production, intersettlement trade, migration, settlement development, detailed/abstract simulation transitions, and changes to persistent regional state.

Expansion 23 — Bandits and criminal careers

Capture criminal decisions, theft, raids, faction activity, smuggling, stolen goods, enforcement, punishment, and downstream economic and social effects.

Do not activate unfinished expansion features merely to test recording.

Preserve existing feature flags and release boundaries.

---

7. Data architecture

Do not continuously construct an Excel workbook during gameplay.

Use an efficient, append-only structured recording system as the authoritative diagnostic archive.

Requirements:

- Persistent structured event records.
- Stable schema versions.
- Permanent entity references.
- Unique interaction and event IDs.
- Causal parent and dependency references.
- Accurate timestamps and ordering.
- Typed values.
- Explicit source-system identification.
- Compression.
- File rotation.
- Bounded in-memory buffers.
- Recovery from interrupted sessions.
- Detection of incomplete writes.
- Explicit reporting of lost or truncated records.
- Configurable storage limits.
- Export of complete diagnostic sessions.

A relational event structure is preferable to a single enormous flat table.

Do not restrict the number of fields merely to simplify Excel output.

Where appropriate, use dedicated tables for decision factors, participants, state changes, and causal links.

Performance requirements

The recorder must not alter:

- Gameplay decisions.
- RNG state.
- Deterministic outcomes.
- Authoritative game state.
- NPC priorities.
- Resource conservation.
- Entity identities.

Benchmark recording overhead on Android and desktop.

Avoid unnecessary allocations, repeated serialization, or expensive disk operations inside time-critical simulation loops.

Record every meaningful executed interaction in full diagnostic mode, rather than silently sampling.

If complete recording cannot be sustained, surface the limitation explicitly and preserve the diagnostic integrity of the session. Do not silently drop records or pretend the archive is complete.

---

8. Excel workbook export

Provide a user-accessible diagnostic export on Android, Windows, and Linux development/playtest builds.

Export a package containing:

1. A readable ".xlsx" workbook.
2. The complete authoritative structured diagnostic records.
3. Session metadata.
4. Recording coverage information.
5. A data dictionary.
6. Diagnostic alerts and validation results.

The workbook should include separate linked worksheets as appropriate:

Worksheet| Contents
Overview| Population, economy, settlements, simulation health, event totals
Interactions| Every recorded interaction and outcome
Events| Chronological event history
Participants| Entity identities and roles in each interaction
Decisions| Decision context and selected action
Decision Factors| Actual evaluated inputs, weights, and modifiers
Alternatives| Considered and rejected actions
State Changes| Authoritative before/after values
Causal Links| Parent, dependency, and downstream relationships
Activities| Work, rest, travel, gathering, consumption
Inventory| Item and resource changes
Currency| Monetary transfers and balances
Transactions| Purchases, sales, negotiations
Contracts| Terms, obligations, fulfillment, breach
Production| Output, inputs, labor, facility operations
Relationships| Personal relationship changes
Judgment| Good/Bad events, observers, ledger effects
Gossip| Information transfer and resulting beliefs
Population| Births, deaths, migration, succession
Households| Membership, resources, relationships
Businesses| Operations, staffing, performance
Settlements| Trade, resources, development, migration
Politics| Elections, officials, taxes, treasury
Crime| Theft, factions, guards, punishment
Alerts| Violations, warnings, suspicious trends
Coverage| Instrumentation completeness by system
Metadata| Build, commit, seed, flags, save version
Data Dictionary| Field definitions, units, source systems

Additional sheets may be necessary.

These are logical tables, not mandatory duplicate copies of the same data. Normalize where appropriate and retain links between records.

Respect Excel's worksheet row limit by splitting large tables into numbered sheets or separate workbooks.

Do not discard events because an Excel worksheet reaches its limit.

The structured archive remains authoritative if the data exceeds Excel's practical capacity.

Make exported data straightforward for ChatGPT or another analysis tool to inspect.

---

9. Automated diagnostic validation

Add invariant checks that detect impossible or contradictory states.

Examples:

- Duplicate permanent identities.
- Identity reuse after death.
- One person simultaneously residing in incompatible locations.
- Lost identity during migration.
- Incorrect identity after succession.
- Negative inventory where prohibited.
- Unexplained item creation or destruction.
- Unexplained currency creation or destruction.
- Double allocation of reserved goods.
- Contract fulfillment exceeding available authorized resources.
- Impossible ownership changes.
- Incorrect state restoration after loading.
- Disabled feature flags affecting gameplay.
- Actions using information unavailable to the decision-maker.
- Contradictory authoritative state across subsystems.

Each violation must record the relevant entity IDs, state values, triggering event, and rule violated.

Behavioral anomaly detection

Also identify suspicious trends that may not represent strict rule violations:

- Persistent shortages.
- Professions becoming economically nonviable.
- Entire populations selecting identical actions.
- Businesses that never acquire customers.
- Villagers who never trade.
- Relationships that never influence decisions.
- Abnormal mortality or migration.
- Unexplained wealth concentration.
- Recurring decision failures.
- Stalled supply chains.
- NPCs trapped in repetitive behavior.
- Extreme performance hotspots.

Classify these as warnings requiring investigation, not automatically as bugs.

A legitimate economic collapse must not be labeled a programming failure merely because the outcome is undesirable.

---

10. Instrumentation coverage audit

Before implementation, inspect the existing repository and identify every meaningful simulation interaction type.

Produce a coverage matrix with these fields:

- System.
- Subsystem.
- Interaction type.
- Execution location.
- Trigger instrumentation.
- Participant instrumentation.
- Decision-factor instrumentation.
- Outcome instrumentation.
- State-change instrumentation.
- Causal-link instrumentation.
- Coverage status.
- Known limitations.

Coverage statuses must distinguish:

- Fully instrumented.
- Partially instrumented.
- Not instrumented.
- Not applicable.

Do not claim 100% coverage based on a list of instrumented systems alone.

Verify actual execution paths.

The coverage audit must account for the currently implemented systems and be extensible as Expansions 20–23 become active.

---

11. Verification and acceptance criteria

The recorder is acceptable for Build 19 when:

1. Every meaningful executed interaction within the defined active simulation scope has a recorded event or an explicitly documented instrumentation gap.
2. All simulated inhabitants are included, not just the player.
3. Actual decision factors and outcomes can be inspected.
4. State changes link to the interactions that produced them.
5. Recorded causal relationships can be traversed.
6. Failed and refused interactions are captured.
7. Identity, economic, and other invariants are checked.
8. A complete diagnostic session can be exported from Android and desktop.
9. The Excel workbook and structured archive agree on record counts and IDs.
10. Recording completeness and limitations are reported accurately.
11. Recording ON versus OFF produces identical deterministic simulation results.
12. Performance overhead and storage growth are measured and documented.
13. A long-running autonomous village simulation can be analyzed without player involvement.
14. Build 18 gameplay behavior remains unchanged where expansion features are disabled.
15. Existing saves and released builds remain protected.

Test actual exports, not merely the presence of export code.

Include a test where the player does nothing while NPCs independently conduct economic and social activity.

Include a multi-day causal tracing test demonstrating that a recorded outcome can be followed backward through its actual contributing interactions.

Reuse existing valid test evidence where applicable. Do not rerun unrelated full suites merely for reassurance.

---

12. Development and release controls

- Do not overwrite or modify the released Build 18.
- Do not merge unrelated expansion branches without authorization.
- Do not activate unfinished gameplay systems.
- Do not publish a release without owner approval.
- Do not replace existing authoritative systems with diagnostic duplicates.
- Do not introduce a second identity or economic ledger.
- Do not fabricate missing event data.
- Do not silently sample or discard diagnostic records.
- Do not make a broad architectural rewrite without demonstrating necessity.
- Preserve deterministic behavior.
- Keep Android, Windows, and Linux build provenance consistent.
- Maintain recovery handoffs before Claude context compaction, which typically occurs around 80%.
- Continue normal parallel expansion work where dependencies permit.

Build 19 must remain a playable milestone, not become an indefinite infrastructure project.

The recorder should be integrated with the Expansion 19 release process after passing its own acceptance criteria.

---

13. Execution instructions

Phase A — Read-only architecture audit

Inspect the current repository and existing simulation systems.

Identify existing event records, decision traces, logging facilities, save structures, identity mechanisms, and export capabilities.

Map the recording requirements against actual code.

Do not assume functionality exists because documentation mentions it.

Phase B — Technical design

Produce:

1. Comprehensive interaction coverage matrix.
2. Proposed diagnostic schema.
3. Causal event mapping architecture.
4. Storage and compression design.
5. Excel export structure.
6. Android and desktop export workflow.
7. Estimated storage requirements for 100, 500, and 1,000 NPC simulations.
8. Expected CPU, memory, and disk overhead.
9. Instrumentation implementation order.
10. Build 19 integration and testing plan.

Identify risks and dependencies, especially the permanent identity foundation and overlapping expansion systems.

Phase C — Owner approval checkpoint

Present the architecture, estimates, risks, and proposed implementation plan.

Ask only for decisions that genuinely require owner authority.

Do not begin a broad implementation before approval.

Phase D — Implementation after approval

Implement the shared recorder foundation first, then instrument Build 18 and Expansion 19 systems, followed by cross-expansion hooks for 20–23.

Ensure diagnostic instrumentation remains separate from authoritative gameplay logic.

Phase E — Validation and export

Run targeted integrity, determinism, performance, recording-coverage, and export checks.

Demonstrate a complete autonomous village recording session.

Produce a sample Excel diagnostic workbook and structured archive for owner inspection.

Report verified coverage, performance, limitations, and any unresolved blockers.

---

Final owner intent

I am personally playtesting My Medieval Life over the coming weeks and months.

I want to be able to play normally, or simply observe a living settlement, and then export the complete simulation history.

I want to hand that export to ChatGPT and ask questions such as:

- Why did this business fail?
- Why did these two villagers stop trading?
- What caused this settlement's economy to deteriorate?
- Which NPCs are behaving abnormally?
- Which systems are failing to influence decisions?
- Where are resources disappearing?
- Which relationships are not working correctly?
- What chain of interactions caused this event?
- Are all systems behaving consistently with the intended simulation rules?

The data must allow these questions to be answered using recorded evidence rather than speculation.

The world exists independently of the player. The recorder must observe the world independently of the player.

Capture every meaningful executed interaction, every actual decision path, every participating system, every authoritative consequence, and every traceable causal relationship across the entire active simulation.

This is the complete Build 19 Simulation Flight Recorder specification.

Begin with the repository audit and technical design. Present findings and the implementation plan for approval before making major changes.
