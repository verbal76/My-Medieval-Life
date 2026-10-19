# Generational memory, wildlife breeding refuges and village politics

Owner directive, received 2026-10-19T17:58:34.441Z (verbatim; kept so approved requirements stay traceable).

---

MY MEDIEVAL LIFE — MASTER DEVELOPMENT DIRECTIVE

Generational Memory, Historical Consequences, Wildlife Breeding Refuges, Population Dispersal, and Living Village Politics

OWNER AUTHORIZATION AND DEVELOPMENT PRIORITY

This is an approved development directive for My Medieval Life.

Add the following major systems to the EXISTING development open-items list and actively begin their implementation:

1. Persistent Generational Memory and Historical Consequences
2. Protected Wildlife Breeding Refuges and Natural Population Dispersal
3. Living Village Politics, Elections, Civic Offices, and Political Reputation

These are permanent world-simulation mechanics, not optional ideas or proposals awaiting additional approval.

Continue existing development work safely. Do not abandon or overwrite active work on carts, assets, multiplayer foundations, or the eight previously approved improvements.

Coordinate these systems with the current roadmap, assign independent workstreams where practical, and integrate tested work into staging.

Do not create duplicate punch lists, duplicate Interlocking Systems Manifests, or competing sources of project truth.

Preserve the existing 16 World Design Rules and any subsequently added rules. Add new rules only after checking the current numbering and avoiding duplicates.

The political system is not a separate minigame. It must be directly connected to generational memory, family relationships, reputation, the economy, crime, employment, property, public safety, and the village's actual history.

---

PART I — PERSISTENT GENERATIONAL MEMORY AND HISTORICAL CONSEQUENCES

1. Core design philosophy

The goal is not merely to give NPCs relationship scores.

The goal is for the world to remember what happened, who made it happen, who benefited, who suffered, and how those consequences shaped later generations.

NPCs must understand their relationships to historical events, the people involved, and the descendants of those people.

A memory must be capable of connecting to other memories, physical objects, properties, professions, family relationships, historical records, and world events.

This must function across multiple generations of NPCs and player characters.

Example: The house built with 30 planks

Generation 1:

Thomas Downs gives William Miller 30 planks when William cannot afford the materials needed to finish his house.

The game records:

- Thomas Downs supplied 30 planks.
- William Miller received them.
- The transfer was voluntary assistance.
- The planks came from Thomas's actual inventory.
- William used those materials toward construction of a specific house.
- The house was completed.
- The event created gratitude and a meaningful relationship between the families.

Generation 2:

William tells his children how Thomas helped build their family home.

His children remember the story as something their father told them, not as an event they personally witnessed.

Generation 3:

A descendant of Thomas Downs visits the house.

William's grandson recognizes the Downs family connection and says something appropriate, such as:

"You're one of the Downs family, aren't you? Your great-grandfather helped my grandfather build this house. Gave him thirty planks when he couldn't afford the timber. We've lived here ever since. You're always welcome."

The NPC must not produce this dialogue from a scripted example or randomly assigned family-history text.

The statement must be generated from actual historical event records, family lineage, knowledge transmission, and the surviving building's history.

If the house was later destroyed, rebuilt, sold, or abandoned, the dialogue must reflect that reality.

The system must know why the NPC remembers the event and what happened afterward.

2. Historical event records

Create or extend a persistent historical event system.

Record meaningful events with structured data, including:

- Unique event ID.
- Event type.
- World date and time.
- Location.
- Participating characters.
- Family and household affiliations at the time.
- Roles of each participant.
- Witnesses.
- Resources or currency involved.
- Quantities and values.
- Relevant property, building, business, or item IDs.
- Immediate outcomes.
- Later consequences.
- Social significance.
- Knowledge provenance.
- Connections to related historical events.

Do not record every trivial movement or repetitive action as a permanent historical event.

Use significance thresholds, aggregation, and appropriate retention rules to keep the system efficient.

Events such as meaningful gifts, rescues, major purchases, construction assistance, crimes, battles, marriages, deaths, inheritances, disasters, and business milestones should be eligible for historical preservation.

3. Causal links between memories

Memories must be capable of referring to other events.

Examples:

- A gift of timber helped construct a house.
- The house became the family home.
- The home was inherited by a child.
- That child later opened a business there.
- The business supported another family during a famine.
- A later descendant remembers the original timber donation as part of the family's history.

Represent these relationships using stable event and entity references.

An event may cause, enable, contribute to, follow from, contradict, or commemorate another event.

Avoid falsely claiming that a particular resource created an outcome unless the simulation can establish a real contribution.

For example, if the game records that 30 donated planks entered a construction inventory, and the house subsequently consumed those planks, it can truthfully connect the gift to the completed house.

If the materials were sold instead, the history must reflect that.

4. Persistent family identity

Integrate historical memory with the existing family, aging, inheritance, and household systems.

NPCs must be able to understand:

- Parents and children.
- Grandparents and grandchildren.
- Great-grandparents and later descendants.
- Siblings and extended relatives.
- Marriage connections.
- Household membership.
- Family names and lineage.
- Former and current property ownership.
- Relationships between two family trees.

This must apply equally to player families and NPC families.

When a player dies and continues as an heir, the world must recognize that heir as a descendant of the previous character.

The heir does not inherit the predecessor's personal memories as firsthand experiences or automatically inherit their skills.

However, the heir may know family stories, inherit property and reputation consequences, and be recognized by other families.

NPCs must distinguish between the person who performed an action and their descendants.

5. Memory acquisition and transmission

NPCs must not have universal knowledge of everything that happens.

Knowledge must come from plausible sources:

- Personal experience.
- Direct observation.
- Conversation.
- Family storytelling.
- Gossip.
- Community gatherings.
- Witness testimony.
- Written records.
- Public announcements.
- Memorials and chronicles.
- Local historical knowledge.

Track whether knowledge is firsthand, secondhand, rumored, documented, or inferred.

Track the source where feasible.

An NPC who was not present at a battle should not describe it as a personal experience unless they actually participated.

A secret crime should not become public knowledge without a believable discovery or transmission path.

Memories may become incomplete, distorted, disputed, or forgotten.

Important events may survive through several generations because they remain meaningful to the affected families.

6. Emotional and social interpretation

Different characters may interpret the same historical event differently.

A soldier might remember a battle as a victory.

A widow might remember the same battle as the day her spouse died.

A merchant might remember that the battle destroyed their inventory.

A descendant might remember it as the event that established their family's standing.

Store meaningful perspectives and consequences without creating an enormous separate copy of every event for every NPC.

Historical memories should influence:

- Trust.
- Gratitude.
- Resentment.
- Friendship.
- Rivalry.
- Employment.
- Trade relationships.
- Assistance.
- Family relationships.
- Marriage decisions.
- Political support.
- Crime reporting.
- Reputation.
- Willingness to share information.
- Dialogue.

Do not make inherited resentment or gratitude an absolute rule.

Descendants should be able to overcome historical conflicts through their own actions.

7. Battles, crimes, rescues, and major world events

Extend the system to preserve meaningful combat and historical incidents.

For battles, record where applicable:

- Combatants and factions.
- Leaders.
- Casualties.
- Survivors.
- Who rescued whom.
- Significant injuries.
- Property damage.
- Retreats and victories.
- Captures.
- Looting.
- Changes in local security.
- Later commemorations.

A surviving veteran should remember their own participation.

A child may later know the battle through a parent's account.

A family may remember that an ancestor died defending the village.

Another family may remember that the same ancestor attacked their relatives.

The system must support conflicting but historically grounded perspectives.

Integrate assault, murder, theft, and other recorded crimes with the existing crime and legal systems.

8. Dialogue grounded in world history

Create reusable, context-sensitive dialogue generation from structured memory records.

Do not depend on thousands of manually written lines or expensive external AI calls.

Use flexible dialogue templates and grammatical rules that can combine:

- Family relationships.
- Historical participants.
- Event types.
- Resource quantities.
- Locations.
- Buildings.
- Time elapsed.
- Emotional interpretation.
- Current circumstances.

An NPC should be able to say:

"Your grandfather helped mine."

Or, when enough information exists:

"Your great-grandfather gave my grandfather thirty planks to finish this house."

Or:

"My father fought beside your grandfather when the bandits attacked."

Or:

"My family hasn't forgotten what yours did to us."

Dialogue must be supported by actual world history, not invented facts.

Use natural variation so NPCs do not repeat the same sentence endlessly.

NPCs should remember whether they have already discussed a particular event with the player.

9. Living historical records

Integrate significant events with:

- The life chronicle.
- Family trees.
- Property histories.
- Memorials and graves.
- Village history.
- The in-game Wiki.
- Existing titles and reputation.
- The Interlocking Systems Manifest.

The player should be able to discover their family's history without every historical detail being revealed automatically.

Preserve meaningful world history across save/load and character death.

---

PART II — PROTECTED WILDLIFE BREEDING REFUGES

10. Core wildlife principle

Wildlife must remain a finite, living population.

Players, NPC hunters, predators, disease, and environmental pressures may devastate a local population.

However, suitable regions must retain a protected breeding refuge from which the species can eventually recover.

The final protected breeding population must never be accessible for hunting or depletion.

Do not simply make the last two visible animals invulnerable.

The protected breeding population should exist inside an inaccessible or concealed refuge.

11. Species-appropriate refuges

Create persistent breeding refuges appropriate to the species.

Examples:

- Wolves: secluded dens or caves.
- Bears: protected caves.
- Boars: concealed woodland shelters.
- Rabbits: burrow systems.
- Deer: sheltered breeding habitat.
- Birds: protected nesting areas.

The refuge may be represented by a lightweight simulation rather than fully modeled accessible terrain.

If a refuge is visually represented in the world, it must not expose the protected breeding animals to player attacks.

Do not force every species to use a literal cave if that would be biologically or visually inappropriate.

12. Protected breeding population

Maintain a protected breeding population sufficient to support gradual species recovery.

It must not be:

- Huntable.
- Lootable.
- Targetable by predators.
- Accidentally destroyed by area attacks.
- Depleted by normal population updates.
- Duplicated by saving and loading.

The protected population is a recovery mechanism, not an infinite supply of instantly available animals.

13. Reproduction and offspring

Refuges periodically produce offspring.

Reproduction must account for:

- Species.
- Season.
- Habitat conditions.
- Available resources.
- Local population density.
- Reproductive intervals.
- Population carrying capacity.

New animals must enter the normal wildlife simulation after leaving the protected refuge.

They become vulnerable to ordinary dangers.

Use age or maturity stages where supported.

If appropriate young-animal assets exist, use them.

Otherwise, implement a consistent temporary visual representation and record the asset opportunity.

14. Natural dispersal

Young animals must not all appear in the same place.

Disperse them over time and space.

For example, several young boars emerging from a protected refuge might:

- Travel north.
- Move east into suitable woodland.
- Follow a southern habitat corridor.
- Settle in different areas.
- Mature and establish separate breeding groups.

Implement species-appropriate:

- Dispersal distances.
- Direction selection.
- Habitat preferences.
- Minimum group spacing.
- Settlement rules.
- Population density limits.
- Movement hazards.
- Territorial behavior where relevant.

Do not use random movement alone as a substitute for meaningful dispersal.

Avoid placing every new animal near the refuge entrance.

15. New wildlife communities

Dispersed animals should be capable of establishing local populations.

Where appropriate, mature animals can reproduce outside the protected refuge.

Local populations should develop distinct histories:

- Founding animals.
- Births.
- Deaths.
- Migration.
- Predation.
- Hunting losses.
- Population growth.
- Local disappearance.
- Recolonization.

Do not simulate unnecessary individual detail for distant animals when a lightweight population model would suffice.

16. Hunting and ecological consequences

The player must still be able to overhunt a region.

If all ordinary deer disappear from a forest, that forest may remain without deer until migrants arrive.

This should affect relevant systems:

- Hunter productivity.
- Meat and hide supply.
- Predator food availability.
- Wildlife encounters.
- Local resource scarcity.
- Trade and prices where appropriate.

Recovery should be gradual and depend on ecological conditions.

Avoid instant respawning that erases the consequences of overhunting.

The protected refuge guarantees a recovery source, not immediate abundance.

17. Wildlife migration and persistence

Save and restore:

- Refuge identity and location.
- Species.
- Breeding schedule.
- Population counts.
- Offspring cohorts.
- Maturity.
- Dispersal destinations.
- Local settlements.
- Habitat capacity.
- Migration state.

Ensure that saving and loading cannot duplicate animals or reset breeding timers.

Integrate the system with existing wildlife AI, navigation, hunting, predators, seasons, and world persistence.

---

PART III — LIVING VILLAGE POLITICS, ELECTIONS AND CIVIC AUTHORITY

18. Political design philosophy

The village must have an actual political and civic system populated by NPCs with individual interests, opinions, memories, families, professions, and economic circumstances.

The player must be able to participate in village politics, but politics must continue independently when the player does nothing.

Villagers must be able to vote in genuine elections based on their individual evaluation of candidates.

A political office is not merely a title, cosmetic badge, or dialogue option.

Holding office must grant defined responsibilities, powers, obligations, limitations, and consequences.

Political reputation must be connected to the same historical events and family relationships used by the generational memory system.

19. Civic positions and careers

Implement or expand civic roles appropriate to the settlement's established government structure.

The owner specifically wants opportunities to become:

- Mayor or equivalent village leader.
- Constable.
- Captain of the Guard.
- Ordinary town guard.

These positions must also be available to eligible NPCs.

Do not assume every office is filled through an election.

Use sensible civic selection methods that fit the world's political structure.

For example:

- Mayor: elected by eligible villagers.
- Constable: elected or appointed according to local rules.
- Captain of the Guard: appointed or promoted through the appropriate authority.
- Guard: hired or recruited into civic employment.

Make these arrangements configurable or extensible so different settlements may develop different political structures.

NPCs must be able to compete for offices and careers without the player's involvement.

20. Real individual voting

Every eligible NPC voter must make an actual individual voting decision.

Do not select an election winner through an arbitrary global popularity roll.

Do not generate a predetermined winner and fabricate votes afterward.

Define voting eligibility according to the settlement's established rules.

For each eligible voter:

1. Identify the available candidates.
2. Evaluate the voter's personal knowledge of each candidate.
3. Consider firsthand interactions.
4. Consider family history and inherited reputation.
5. Consider trusted testimony and gossip.
6. Consider candidate conduct and competence.
7. Consider economic interests.
8. Consider public safety and crime.
9. Consider the candidate's policies and past performance.
10. Consider competing personal loyalties.
11. Produce an individual vote or abstention.
12. Record the actual election result.

Voting must be deterministic or reproducible under the game's existing seeded simulation requirements.

The election result must be calculated from the actual votes cast.

21. Generational political reputation

A candidate's family history must influence political support when voters actually know that history.

Example:

Thomas Downs helps William Miller build his home by donating thirty planks.

William tells his descendants.

Several generations later, Thomas's descendant runs for mayor.

William's descendants may support the Downs candidate because their family remembers that assistance.

An NPC might say:

"My grandfather told me how your family helped build our house. Your people have always looked after ours. You've got my vote."

But this must not be automatic.

A descendant may respect the Downs family and still vote against the candidate because:

- The candidate personally behaved dishonestly.
- Another candidate has better policies.
- The voter's business would suffer.
- The candidate neglected village safety.
- The candidate committed a serious crime.
- The voter has stronger personal loyalty to someone else.

Family reputation influences voting; it does not override individual judgment.

The same system must support inherited grievances.

A family harmed by a previous mayor may distrust that mayor's descendants until later actions change their opinion.

22. Political opinions and individual priorities

NPCs must have meaningful political priorities derived from their circumstances.

Examples:

A farmer may care about agricultural taxes, livestock safety, land access, and food prices.

A merchant may care about trade, roads, market regulations, and security.

A guard may care about wages, equipment, crime, and public order.

A struggling household may prioritize food availability and fair taxation.

A wealthy landowner may prioritize property protection and commercial stability.

A villager whose family suffered from bandit attacks may strongly favor better defenses.

These priorities must interact with the actual world simulation.

Do not randomly assign meaningless political opinions disconnected from NPC needs.

Opinions should be capable of changing as conditions change.

23. Political campaigns and candidacy

Allow eligible player characters and NPCs to seek political office.

Implement meaningful candidacy requirements and campaign activity appropriate to the settlement.

Possible activities include:

- Declaring candidacy.
- Discussing village problems.
- Meeting voters.
- Making campaign promises.
- Public debates or gatherings.
- Demonstrating civic service.
- Building coalitions.
- Seeking endorsements.
- Responding to accusations.
- Presenting a record of past accomplishments.

Do not make campaigning a repetitive dialogue-clicking minigame.

Existing relationships, demonstrated competence, actual service, and historical actions should matter more than repeatedly selecting a persuasion option.

NPC candidates must also campaign or build support through simulated behavior.

24. Election schedules and procedures

Establish actual election cycles.

Define:

- Office terms.
- Eligibility.
- Nomination or candidacy rules.
- Voting dates.
- Candidate registration.
- Voter eligibility.
- Ballot evaluation.
- Vote counting.
- Tie resolution.
- Vacancies.
- Resignation.
- Death in office.
- Succession or replacement elections.

The political process must continue even if the player never participates.

Do not leave civic offices vacant indefinitely because the player ignores politics.

Persist election dates, candidates, voters, ballots or vote records as appropriate, and outcomes across save/load.

Ensure elections cannot duplicate or change results when the game is reloaded.

25. Meaningful authority and responsibilities

Political offices must have actual gameplay responsibilities.

Mayor

The mayor should influence or administer appropriate civic functions such as:

- Village spending priorities.
- Public works.
- Local taxes within established rules.
- Guard funding.
- Civic appointments.
- Village improvements.
- Responses to emergencies.
- Public resource allocation.

Constable

The constable should participate in:

- Law enforcement.
- Investigations.
- Arrests or lawful apprehension.
- Crime records.
- Local disputes.
- Coordination with guards.
- Public safety.

Captain of the Guard

The captain should participate in:

- Guard assignments.
- Patrol priorities.
- Training.
- Equipment.
- Defense readiness.
- Responses to bandit threats.
- Guard discipline.

Ordinary Guard

Guards should perform actual duties such as:

- Patrols.
- Responding to crimes.
- Protecting villagers.
- Investigating disturbances.
- Defending the settlement.
- Reporting to superiors.

Connect these jobs to real wages, schedules, equipment, resources, and the village treasury.

Do not create civic employees who receive unlimited money or equipment from nowhere.

26. Public accountability

Political decisions must have measurable consequences.

A mayor who improves roads, funds defenses, and maintains stable taxes may gain support.

A mayor who wastes treasury funds, neglects public safety, or unfairly favors one family may lose support.

Villagers should remember:

- Promises made.
- Promises kept.
- Promises broken.
- Taxes imposed.
- Public works completed.
- Emergencies handled.
- Corruption or favoritism.
- Successful defenses.
- Failures of leadership.

These become historical events that influence future elections.

Where appropriate, allow removal from office, replacement, loss of political support, or other consequences through the established political system.

Do not create unlimited mayoral authority or ignore the settlement's existing laws and resources.

27. Politics and the economy

Political decisions must affect actual economic conditions.

Examples:

- Guard funding consumes real treasury money.
- Road improvements consume actual construction resources and labor.
- Tax changes affect households and businesses.
- Public projects create demand for professions.
- Poor administration may cause shortages or dissatisfaction.
- Better security may reduce trade disruption.
- Civic wages affect employment decisions.

Connect these consequences to the existing economy.

Do not generate money, supplies, or public works without real sources.

Use the updated economic measurement tools to evaluate political consequences.

28. Politics and generational history

Political events must become part of the world's persistent history.

Record:

- Elections.
- Candidates.
- Vote totals.
- Officeholders.
- Terms served.
- Major policies.
- Public projects.
- Scandals.
- Resignations.
- Deaths in office.
- Public achievements.
- Significant political conflicts.

Descendants should be able to remember and discuss their ancestors' political careers.

Examples:

"Your grandfather was mayor when the old bridge was built."

"My family still remembers the taxes your great-grandmother imposed."

"Your father commanded the guard when the bandits attacked."

"The Millers supported your family for three elections, but that changed after the grain shortage."

Such dialogue must be grounded in actual historical records.

29. NPC political autonomy

NPCs must be able to:

- Seek office.
- Support candidates.
- Change political opinions.
- Campaign.
- Vote.
- Accept appointments.
- Perform civic duties.
- Resign.
- Lose elections.
- Retire.
- Die and be replaced.

Political activity must continue without player intervention.

A player should be able to spend several generations farming, trading, or adventuring while the village experiences its own elections, leadership changes, and political history.

30. Political information and imperfect knowledge

NPC voters must not have omniscient knowledge.

They may know candidates through:

- Personal interactions.
- Family history.
- Reputation.
- Public service.
- Campaign activity.
- Gossip.
- Witnessed crimes.
- Public records.
- Trusted relationships.

A secret crime should not automatically affect an election unless it becomes known.

Rumors may influence voters, but their credibility should depend on the source and the voter's judgment.

Candidates should not automatically know how every villager intends to vote.

31. Election transparency and player feedback

Provide an understandable election interface.

Players should be able to see appropriate public information such as:

- Offices available.
- Election dates.
- Candidate names.
- Public platforms.
- Eligibility requirements.
- Election results.
- Vote totals.
- Current officeholders.
- Terms remaining.

Do not expose every NPC's private voting decision as public information unless the settlement's voting rules explicitly permit it.

The player should be able to understand why their campaign succeeded or failed through believable feedback, without revealing hidden simulation information.

32. Political integration tests

Create automated tests demonstrating that:

1. Every eligible NPC voter makes an individual decision.
2. Election results equal the actual votes counted.
3. The same saved election cannot be counted twice.
4. A historical family favor can influence a descendant's vote.
5. A candidate's personal misconduct can outweigh inherited goodwill.
6. NPC economic circumstances affect political preferences.
7. A candidate can lose despite having strong family reputation.
8. NPCs can win elections without player involvement.
9. Civic offices remain functional after death, retirement, or resignation.
10. Public spending consumes real treasury resources.
11. Political actions become persistent historical events.
12. Descendants can accurately discuss an ancestor's political career.
13. Save/load preserves elections, offices, and civic history.
14. Single-player functionality remains intact.

Include a multigenerational integration scenario:

Thomas Downs donates thirty planks to William Miller's house.

William's family preserves the story.

Several generations later, a Downs descendant runs for mayor.

A Miller descendant recognizes the historical connection and factors it into their vote.

The result must arise from actual memory and voting logic, not a hardcoded special case.

---

PART IV — SHARED SIMULATION ARCHITECTURE

33. Build reusable historical foundations

All three systems depend on persistent world state.

Where practical, use shared infrastructure for:

- Stable entity identities.
- World timestamps.
- Historical event references.
- Save/load migration.
- Efficient long-term simulation.
- Entity lifecycle tracking.
- Regional histories.
- Family relationships.
- Political and ecological event records.

However, do not overengineer a universal framework that delays playable features.

Human social memory, wildlife population tracking, and political simulation should remain distinct gameplay systems with appropriately shared infrastructure.

34. Performance requirements

The game may simulate many NPCs, families, animals, elections, and generations.

Do not retain unbounded per-frame or per-interaction histories.

Use:

- Event significance thresholds.
- Historical summaries.
- Indexed relationships.
- Lightweight offscreen simulation.
- Bounded active-memory retrieval.
- Efficient save formats.
- Appropriate archival rules.

Preserve important historical facts and causal links while preventing uncontrolled memory growth.

A major historical event should remain discoverable even if the original participants have died.

35. Multiplayer compatibility

The current game remains single-player while player-hosted multiplayer is being developed separately.

Design these systems so a future host-authoritative multiplayer world can use them.

The host must be the authority for:

- Historical events.
- Resource transfers.
- NPC memory changes.
- Family lineage.
- Wildlife births and deaths.
- Population migration.
- Political elections.
- Civic appointments.
- Vote counting.
- Save persistence.

Do not introduce competing client-side world histories, election results, or independent wildlife simulations.

Do not turn this directive into a full multiplayer implementation task.

---

PART V — IMPLEMENTATION, TESTING, AND DOCUMENTATION

36. Existing open-items list

Locate the project's authoritative open-items list or development ledger.

Add all three systems as approved, active development work.

Use the existing numbering and status conventions.

Break them into manageable implementation tasks with dependencies and verification requirements.

Do not create a second competing backlog.

The work must remain visible across future builds until complete.

Check for existing political tasks and extend them rather than creating duplicates.

37. Implementation order

Use this general sequence, adapting to actual code dependencies.

Generational memory

1. Audit existing family, lineage, relationship, dialogue, and historical systems.
2. Establish stable event and entity references.
3. Record meaningful social and economic events.
4. Link events to buildings, resources, and outcomes.
5. Implement knowledge transmission and family memory.
6. Add context-sensitive dialogue.
7. Connect memory to social and economic behavior.
8. Integrate battles, crimes, and historical chronicles.
9. Validate multigenerational persistence.

Wildlife breeding

1. Audit existing wildlife population and breeding logic.
2. Create protected refuges.
3. Implement reproduction schedules.
4. Introduce offspring cohorts.
5. Implement dispersal and habitat selection.
6. Establish new local populations.
7. Connect hunting, predation, and recovery.
8. Validate long-running population behavior.

Living village politics

1. Audit existing political authority, guard employment, taxation, and civic systems.
2. Define offices, eligibility, and civic responsibilities.
3. Implement individual NPC voting.
4. Connect voting to relationships and historical memory.
5. Implement election cycles and succession.
6. Add NPC candidacy and campaigning.
7. Add player candidacy and political participation.
8. Implement civic powers and actual resource consequences.
9. Connect political actions to historical records.
10. Validate elections across generations and save/load.

Start meaningful implementation work, not just planning documents.

Prioritize shared memory infrastructure where it enables several systems.

38. Automated tests

Create tests for generational memory, including:

- A gift of exactly 30 planks being recorded accurately.
- The planks being consumed by an actual construction project.
- The resulting house retaining a reference to its construction history.
- The original participants dying.
- Descendants recognizing the family relationship.
- A descendant accurately recalling the historical assistance.
- The dialogue referring to the correct house and quantity.
- A different descendant without access to the story not knowing it automatically.
- Rumors being distinguished from witnessed events.
- Conflicting historical perspectives.
- Save/load preserving memories and causal relationships.
- Historical memories affecting behavior without permanently determining it.

Create tests for wildlife, including:

- Protected breeding populations surviving local extinction.
- Hunters and predators being unable to access protected breeders.
- Offspring emerging gradually.
- Young animals dispersing to different areas.
- Minimum spacing between new groups.
- Habitat and carrying-capacity limits.
- Local population depletion.
- Gradual recolonization.
- Persistence across save/load.
- No animal duplication.
- Long-run population stability.

Create the political tests specified in Section 32.

Where feasible, run multigenerational and multi-year simulation tests.

Do not substitute mocked test success for actual integrated behavior.

39. In-game Wiki and developer documentation

Every completed player-facing mechanic must be documented in the existing in-game Wiki.

Add or update entries explaining:

- Family history.
- NPC memories.
- Generational reputation.
- Historical events.
- Family chronicles.
- Battles and memorials.
- Wildlife reproduction.
- Local extinction.
- Migration.
- Wildlife recovery.
- Political offices.
- Elections.
- Voting.
- Campaigning.
- Civic employment.
- Guard careers.
- Taxation and public spending.
- Political reputation.
- Political succession.
- Historical leadership.

Do not describe unimplemented functionality as playable.

Update developer documentation for event schemas, memory transmission, dialogue, population models, voting calculations, election persistence, civic authority, save migrations, and performance.

Maintain the existing Interlocking Systems Manifest.

Document newly established dependencies and interactions.

No gameplay mechanic is considered complete until its relevant Wiki entries, developer documentation, and manifest references are updated and verified.

40. Permanent World Design Rules

Review the current permanent World Design Rules.

If no equivalent rule already exists, add the next available numbered rule covering:

Generational Memory and Living History

Significant actions must be capable of becoming persistent historical events whose consequences can influence future generations. NPC knowledge must have plausible sources, familial relationships must be understood, and memories must connect to actual people, resources, properties, and outcomes.

Add a separate rule if needed for:

Protected Ecological Continuity

Wildlife populations must be finite and responsive to hunting and environmental pressures while protected breeding refuges allow gradual, habitat-dependent recovery through reproduction and dispersal.

Add or extend a rule covering:

Living Political Agency and Democratic Consequences

Eligible NPCs must cast genuine individual votes based on their knowledge, relationships, family histories, interests, and assessment of candidates. Political offices must have real responsibilities and consequences. Elections, governance, and political succession must continue independently of the player and persist across generations.

Use the existing rule numbering and documentation structure.

Do not duplicate existing rules, including the established rule concerning political authority, social hierarchy, and civic employment.

41. Completion criteria

Generational memory

Generational memory is not complete merely because NPCs have relationship scores.

It must demonstrate a real multigenerational event chain, including:

- A historical action.
- A real resource or world-state consequence.
- A persistent causal relationship.
- Knowledge transmitted to descendants.
- Correct recognition of family lineage.
- Context-sensitive dialogue.
- A meaningful behavioral consequence.

Wildlife recovery

Wildlife recovery is not complete merely because animals respawn.

It must demonstrate:

- A protected breeding refuge.
- Gradual reproduction.
- Dispersal into suitable habitats.
- Formation of separate local populations.
- Local depletion through hunting.
- Gradual recolonization.
- Stable long-term persistence.

Living politics

The political system is not complete merely because the player can acquire a mayor title.

It must demonstrate:

- Actual NPC candidates.
- Actual individual voters.
- Election results calculated from votes.
- Historical family relationships influencing political preferences.
- Individual judgment overriding inherited loyalties when appropriate.
- NPC political participation without player involvement.
- Meaningful civic authority.
- Real economic and social consequences.
- Political history preserved across generations.
- Correct save/load persistence.

42. Final reporting

Provide progress reports using the existing development reporting process.

For each system, report:

- Open-item IDs.
- Implementation status.
- Relevant commits.
- Files changed.
- Tests added.
- Tests passed or failed.
- Wiki entries updated.
- Interlocking Systems Manifest changes.
- Known limitations.
- Next development tasks.

Do not declare any system complete until its integration tests and persistence requirements pass.

Continue working autonomously within the existing development priorities.

---

FINAL DESIGN INTENT

The intended result is a world where:

A person's actions can shape another family's life for generations.

A villager can remember that the player's great-grandfather supplied thirty planks to build the house they still live in, because that event genuinely happened in the simulation.

Wildlife populations establish, disappear, migrate, and recover through believable ecological processes.

A forest can recover from overhunting because young animals emerged from protected breeding refuges, dispersed, matured, and established new populations.

Political power emerges from real relationships, individual decisions, and historical consequences.

A player's descendant can run for mayor and receive votes from villagers whose families remember past kindnesses, while other villagers vote against that same candidate because of their own experiences, priorities, or grievances.

A mayor's decisions can change the village economy, guard effectiveness, public safety, and future elections.

A guard can rise through the ranks to become captain.

A constable can enforce laws that apply to both the player and NPCs.

An NPC can become mayor without the player ever seeking office.

And generations later, villagers can remember who led them, who helped them, who betrayed them, and what happened to their town as a result.

The player should not be the center of the simulation. The player should be one participant in a world with its own families, wildlife, politics, economy, and history.

That is the standard all three systems must meet.
