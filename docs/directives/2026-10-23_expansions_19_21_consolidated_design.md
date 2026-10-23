# Owner directive, 2026-10-23: Expansions 19, 20 and 21 consolidated design directive

Saved verbatim.

---

MY MEDIEVAL LIFE — EXPANSIONS 19, 20 & 21

Consolidated Owner Design Directive

System Breadth, Mechanics, Integration, and Development Boundaries

Project: Hot Attic Games — My Medieval Life
Applies to: Expansion 19 (Subjective Judgment), Expansion 20 (Living Economy), Expansion 21 (Politics and Civic Authority)
Directive type: Design consolidation, architectural review, and development guidance
Authorization: No new implementation, feature activation, merging, or releases authorized by this directive.

---

1. PRIMARY DESIGN PHILOSOPHY

My Medieval Life is intended to simulate a living medieval world whose inhabitants pursue their own interests, form relationships, develop skills, conduct business, participate in government, and react to events independently of the player.

The purpose is not to script every conceivable interaction.

The purpose is to create sufficiently broad, interconnected systems that believable behavior emerges naturally.

The NPC decision engine must generate outcomes from circumstances, personality, knowledge, resources, and experience rather than relying on hundreds of special-case behavioral scripts.

Every major system must answer:

1. What can this system do?
2. How far does its influence extend?
3. What other systems does it affect?
4. What information and resources does it require?
5. What are the consequences of its actions?
6. Can it operate independently of the player?
7. Can it fail naturally without artificial rescue mechanisms?

Do not confuse design depth with the number of individual edge cases documented.

2. EXPANSION 19 — SUBJECTIVE JUDGMENT AND UNIVERSAL DECISION ENGINE

2.1 Intended breadth

Expansion 19 provides the subjective social and behavioral layer used throughout the simulation.

It must support:

- Personal moral judgments.
- Trust and reliability.
- Familiarity and respect.
- Family reputation and inherited social perceptions.
- Friendships, rivalries, and romantic relationships.
- Gossip and information propagation.
- Deliberate misinformation.
- Forgiveness and reconciliation.
- Personality differences and behavioral tendencies.
- Learning from experience.
- Memory and changing opinions.
- Decisions influenced by relationships without being dictated by them.

These are interconnected mechanisms, not isolated features.

2.2 Core judgment model

Preserve the established separate Good and Bad judgment ledgers.

Observers interpret events subjectively according to their relationship to the people involved, their existing beliefs, and their own characteristics.

The resulting opinion influences decisions but does not automatically determine them.

A villager may trade with someone they dislike because the goods are necessary, or refuse a profitable opportunity because of fear, pride, or distrust.

The system must distinguish:

- Objective events.
- Information an NPC possesses.
- Whether that information is accurate.
- Subjective interpretation.
- Personal judgment.
- Actual decision and behavior.

2.3 Information and reputation

Approved principles:

- Reputation can extend through a recognized family name.
- Individual observers evaluate family members differently according to knowledge and experience.
- Family reputations can recover through positive conduct, depending on what observers learn.
- Important family stories may survive generations.
- Minor stories can fade when no longer transmitted.
- NPCs may deliberately fabricate false accusations.
- Listeners evaluate credibility, and accusations can be investigated.
- When an NPC learns that a particular accusation has been proven false, the negative judgment caused by that accusation is immediately corrected.
- Independent grievances and memories remain.
- Deliberate dishonesty carries consequences based on intent, harm, repetition, and the observer's relationships.

Do not implement a global omniscient reputation score that automatically informs every NPC.

Information must have a plausible path between individuals and settlements.

2.4 Personality, trust, and learning

Preserve the established principles:

- NPCs have different personality mixes.
- Extreme personalities are uncommon.
- Trust and moral opinion are separate.
- Forgiveness and restoration of trust are separate outcomes.
- Trust may recover through sustained reliability.
- NPCs can make decisions against their immediate economic interests.
- NPCs learn from significant mistakes.
- Experiences can gradually change personality and future decisions.
- Major emotional events can temporarily influence behavior.
- Important grievances can remain meaningful for long periods.

Preserve the previously approved calibration targets and existing deterministic simulation requirements.

Do not convert population-level tendencies into independent random chances applied to every decision.

2.5 Required integration breadth

Map Expansion 19 against all relevant systems, including:

- Trade and price negotiation.
- Employment and workplace relationships.
- Loans, credit, and contracts.
- Family formation and marriage.
- Household cooperation.
- Crime and law enforcement.
- Political elections and public office.
- Business competition.
- Bandit factions.
- Social assistance.
- Migration.
- Settlement relationships.
- Historical records.

Judgment should influence these systems through shared interfaces, not by duplicating their internal logic.

2.6 Architecture and performance

Maintain deterministic, seeded behavior.

Use event-driven updates, sparse relationship records, bounded memory, and efficient information propagation.

Avoid population-wide relationship recalculation every frame.

Preserve the existing feature flag and do not activate unfinished integration.

Development objective: One reusable subjective decision framework capable of influencing the entire world.

3. EXPANSION 20 — LIVING ECONOMY

3.1 Intended breadth

Expansion 20 provides the economic foundation for individuals, households, businesses, settlements, and eventually regional trade.

It must support:

- Individual supply and demand.
- Negotiated prices.
- Production and supply chains.
- Business ownership and operation.
- Employment and labor markets.
- Economic competition.
- Credit and debt.
- Contractual obligations.
- Household finances.
- Trade and transportation.
- Shortages and surpluses.
- Business growth and failure.
- Economic change over time.

The economy must function without the player.

3.2 Market structure

Approved decision: Combined market pricing.

Supply, demand, scarcity, and completed transactions inform asking prices.

Buyers and sellers negotiate actual deals.

Approved negotiation behavior:

- Limited counteroffers.
- Individual willingness to compromise.
- Influence from urgency, alternatives, experience, and personality.
- No guaranteed transaction simply because a mathematical price range overlaps.

Markets should operate through real buyers, sellers, inventories, money, knowledge, and transport constraints.

3.3 Business and production breadth

Assess the architecture needed for:

- Independent NPC-owned businesses.
- Multiple businesses under common ownership.
- Hiring workers and managers.
- Acquiring tools and production equipment.
- Purchasing inputs.
- Producing intermediate and finished goods.
- Selling to households and other businesses.
- Competing for workers, materials, customers, and locations.
- Expanding or downsizing operations.
- Business insolvency and closure.

These are capability areas to evaluate, not blanket authorization to implement every proposed business feature.

The existing profession, industry capability, production, and inventory systems must remain authoritative.

3.4 Contracts

Preserve negotiated quantity-based contracts for tradable products.

Contracts must represent:

- Buyer and seller.
- Item and quantity.
- Unit price.
- Delivery obligations.
- Payment obligations.
- Timing and fulfillment status.
- Breach and renegotiation.

Approved decision: Contract breaches have context-sensitive consequences.

Parties may negotiate partial delivery, extensions, changed payment terms, or cancellation depending on the original agreement and circumstances.

Do not assume every breach triggers an automatic penalty.

3.5 Credit, debt, and collateral

Approved decisions:

- Borrowers may negotiate extensions, installments, or payment in goods.
- Specifically pledged collateral may be claimed when the contract permits it.
- Collateral valuation is defined by the agreement.
- When collateral value exceeds the outstanding debt, the surplus must be returned to the borrower.

Do not create automatic authority to seize unrelated property.

Additional lending products and enforcement procedures remain subject to the existing specification and unresolved owner decisions.

3.6 Economic conservation

Preserve finite inventories and currency.

No transaction may create or destroy money or goods without an explicitly modeled source or sink.

No artificial guaranteed market demand.

No automatic village rescue.

Economic consequences must propagate through connected systems.

For example, a mine shortage can affect smelters, blacksmiths, construction, employment, prices, and household purchasing power.

This propagation should emerge from shared economic dependencies rather than scripted shortage scenarios.

3.7 Integration breadth

Map Expansion 20 against:

- Expansion 18 industry capability and worker experience.
- Expansion 19 judgment and trust.
- Mining and finite resources.
- Farming and forestry.
- Crafting and production.
- Housing and construction.
- Merchant caravans.
- Settlement growth.
- Regional trade.
- Public treasuries and government purchasing.
- Bandit activity and stolen goods.
- Historical and household records.

Reuse existing authoritative inventories, transaction services, and economic ledgers.

Development objective: A finite, interconnected economy where economic opportunity, scarcity, prosperity, and failure arise naturally.

4. EXPANSION 21 — POLITICS AND CIVIC AUTHORITY

4.1 Intended breadth

Expansion 21 introduces functioning settlement government and political careers.

It must support:

- Elected leadership.
- Civic offices and government duties.
- Public treasuries.
- Taxation and public spending.
- Law enforcement and civic administration.
- Elections and political competition.
- Government succession.
- Political reputation and influence.
- Infrastructure decisions.
- Government success and failure.
- NPC participation independent of the player.

4.2 Approved mayoral structure

The owner has approved:

- Mayors are elected.
- Mayoral terms last four in-game years.
- Incumbents may seek reelection.
- Established adult residents are eligible to vote.
- Eligible voters are also eligible to run for mayor.
- An early vacancy triggers a replacement election as soon as possible.
- The longest-serving eligible civic official temporarily assumes authority until the replacement election.
- Individual voters evaluate candidates according to policies, competence, personal interests, trust, relationships, family connections, and their own priorities.

The exact residency qualification duration has not yet been approved.

Do not invent a fixed residency period.

4.3 Government structure and jurisdiction

Evaluate the architecture needed for:

- Individual settlement governments.
- Councils and civic officials.
- Government jurisdiction.
- Relationships between villages and larger settlements.
- Existing manor or noble authority.
- Public property and infrastructure.
- Local laws and administrative authority.

The elected mayor requirement is approved.

Broader feudal hierarchy, regional government, and council powers require further design decisions.

Do not assume every settlement must have identical administrative complexity.

4.4 Civic economy

Government must use real resources.

Public treasuries may receive money through authorized taxes, fees, fines, rents, or duties.

Spending must draw from available funds.

Evaluate integration for:

- Guard payroll.
- Public infrastructure.
- Maintenance.
- Civic employees.
- Public purchasing.
- Emergency expenditures.
- Settlement improvements.

Expansion 20 remains authoritative for financial transactions.

Expansion 21 must not create a separate unlimited-money government economy.

4.5 Political competition

Evaluate the capability boundaries for:

- Candidates seeking office.
- Campaigning.
- Political promises.
- Public approval and disapproval.
- Competing economic interests.
- Political alliances and factions.
- Officeholder performance.
- Corruption and abuse of authority.
- Changes in government policy.

Do not implement all these mechanics automatically.

Identify which are essential to the approved mayoral system and which require separate authorization.

4.6 Law enforcement and government duties

Preserve Rule 015 requirements for meaningful civic employment.

Guards must perform actual duties rather than existing as decorative NPCs.

Law enforcement effectiveness should depend on real staffing, resources, equipment, authority, and information.

Map future interfaces with crime, investigations, bandit factions, and civic justice.

Do not invent legal procedures or punishments that the owner has not approved.

4.7 Political autonomy and history

NPCs must be able to participate in government without player involvement.

Political leadership may change over generations.

Officeholders must have real duties and consequences.

Political careers, offices held, and major accomplishments should persist in historical records.

Development objective: A functioning civic system where government emerges as another part of the living simulation rather than a collection of scripted quests.

5. CROSS-EXPANSION OWNERSHIP

Maintain clear boundaries between the three systems.

Responsibility| Authoritative expansion
Personality, beliefs, subjective opinion, trust| 19
Gossip, reputation, personal memory| 19
Market offers, pricing, contracts, debt| 20
Goods, money, economic obligations| 20, integrated with existing inventory and ledger systems
Political offices, elections, civic authority| 21
Government purchasing, taxes, civic wages| 21 initiates, 20 executes economically
Voting decisions| 21 requests decisions, 19 supplies relevant subjective influences
Business negotiations| 20 owns transactions, 19 influences individual willingness
Crime investigations| Existing crime system and future civic authority integration, without duplicate ownership

Do not create multiple competing NPC brains.

Do not duplicate inventories, financial ledgers, social memory, or political records.

6. REQUIRED ARCHITECTURAL REVIEW

For each expansion, produce a system-level capability matrix with:

1. Capability.
2. Approved design requirement.
3. Existing implementation.
4. Missing functionality.
5. Authoritative subsystem.
6. Dependencies.
7. Performance considerations.
8. Open owner decisions.
9. Recommended development phase.

Classify each capability as:

- Approved: Established owner requirement.
- Existing: Already implemented and verified in the repository.
- Proposed: Potential addition not yet approved.
- Blocked: Requires an owner decision or prerequisite.
- Deferred: Not required for the current development phase.

A proposed capability must not be silently promoted to an approved requirement.

7. QUESTIONS FOR THE OWNER

Stop asking isolated hypothetical social questions unless they expose an actual architectural problem.

Future questions should address:

- System breadth.
- Major gameplay capabilities.
- Architectural boundaries.
- Scale and performance.
- Cross-system integration.
- Meaningful player and NPC opportunities.
- Fundamental economic or political rules.
- Decisions that would cause substantial rework if guessed incorrectly.

Before asking, determine whether the existing specification already answers the question.

For every unresolved question, explain:

1. Why the decision matters.
2. Which systems it affects.
3. Whether development is actually blocked.
4. The practical tradeoffs between the available options.
5. Your recommended approach.

Group related decisions rather than interrupting development with a long sequence of minor questions.

8. DEVELOPMENT EXECUTION RULES

This directive does not override existing build authorizations.

- Continue Expansion 19 only within its currently approved scope.
- Continue Expansion 20 LE-00 and authorized isolated foundation work.
- Continue Expansion 21 architecture and foundation preparation within its existing authorization.
- Respect the two active development-agent slots.
- Do not interrupt active workers unnecessarily.
- Preserve existing feature flags.
- Do not activate incomplete systems.
- Do not merge or publish without explicit approval.
- Reuse valid passing test evidence rather than repeating expensive full test campaigns.
- Maintain recovery handoffs before approximately 80% context usage.
- Record owner decisions in the appropriate registers.

9. REQUIRED RESPONSE

Return a consolidated Expansion 19–21 Development Alignment Report.

For each expansion, provide:

- Current implementation status.
- Approved system breadth.
- Major missing capabilities.
- Existing reusable architecture.
- Cross-expansion dependencies.
- Genuine architectural blockers.
- Recommended next development phase.

Then provide a short Owner Decision Packet containing only unresolved decisions that materially affect architecture or gameplay breadth.

Do not begin another round of scenario-level questioning.

Do not expand the authorized implementation scope merely because this directive describes future capabilities.

The goal is to build three powerful, interconnected systems capable of generating believable behavior, not to manually script every possible human interaction.
