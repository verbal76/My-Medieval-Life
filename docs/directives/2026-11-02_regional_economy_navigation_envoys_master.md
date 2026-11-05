# Owner master directive, 2026-11-02: regional economy, world navigation, envoys and independent inter-village commerce (REGION-NAV-01)

Received in session, verbatim:

> MY MEDIEVAL LIFE — MASTER DEVELOPMENT DIRECTIVE
>
> Regional Economy, World Navigation, Envoys, and Independent Inter-Village Commerce
>
> Claude, this is an owner-approved development directive for My Medieval Life.
>
> We have identified a major gap in the game's intended living-world simulation. My Medieval Life is supposed to contain multiple functioning villages with independent economies, physical travel, communication, trade, and economic opportunities.
>
> However, during my own playtesting, I never encountered another village. Our recent business-founding investigation also focused almost entirely on local demand, without establishing whether other villages have goods and services our villagers need.
>
> We are correcting that.
>
> CORE DESIGN PRINCIPLE
>
> The world must operate as a collection of independent but interconnected settlements.
>
> Information travels through people. Goods travel through actual transportation. Money changes hands through legitimate transactions. Economic decisions belong to individual NPCs.
>
> The mayor's envoys discover and communicate opportunities. They do not control commerce.
>
> Our standing development principle applies throughout:
>
> Anything unresolved is a reason to dig. You cannot improve what you don't verify.
>
> ---
>
> PHASE 1 — COMPLETE EXISTING-SYSTEM AUDIT
>
> Before modifying production systems, inspect the repository and establish exactly what already exists.
>
> Investigate:
>
> 1. World generation and multiple-village placement.
> 2. Settlement coordinates, distances, roads, paths, and terrain.
> 3. Player movement between settlements.
> 4. NPC travel and pathfinding.
> 5. Existing local and world-map functionality.
> 6. Village discovery and persistent exploration knowledge.
> 7. Independent settlement populations and economies.
> 8. NPC businesses, professions, inventories, and production.
> 9. Local and regional demand calculations.
> 10. Merchant travel, purchasing, selling, and contracts.
> 11. Mayoral leadership, succession, and NPC task scheduling.
> 12. NPC communication, memory, and information sharing.
> 13. Business founding and the existing 35% utilization requirement.
> 14. Save/load persistence and deterministic simulation.
> 15. Long-duration simulation coverage and performance.
>
> For every system, classify it as implemented and verified, implemented but disconnected, partially implemented, missing, or defective.
>
> Trace actual execution paths. Do not assume functionality exists simply because a class or function has the appropriate name.
>
> Investigate why the player has not encountered another village.
>
> Document the findings with exact code references and supporting evidence.
>
> Resolve significant unknowns through focused investigation rather than leaving them as unsupported assumptions.
>
> PHASE 2 — WORLD MAP AND SETTLEMENT DISCOVERY
>
> Implement a practical two-level navigation system.
>
> Local map
>
> Preserve existing local-map functionality while improving it where necessary.
>
> Display the current village, nearby geography, useful buildings, roads, landmarks, and player location.
>
> World map
>
> Add a toggle between the local map and a regional world map.
>
> The world map should display:
>
> - The player's current position and home village.
> - Discovered villages and their names.
> - Known roads and travel routes.
> - Rivers, forests, mountains, and other relevant geography.
> - Known travel destinations.
> - Previously explored areas.
> - Undiscovered areas without revealing information the player has not legitimately obtained.
>
> The map must use the actual game's world coordinates and terrain.
>
> Do not create a decorative map disconnected from the playable world.
>
> Discovery
>
> Players must be able to discover settlements by physically exploring the world.
>
> They may also learn settlement locations from NPCs, travelers, merchants, and envoys who legitimately possess that knowledge.
>
> Discovered locations must persist through save/load.
>
> Knowledge of a village's location must not automatically reveal all its economic information.
>
> Travel
>
> Investigate and implement reliable travel between reachable villages using existing movement and pathfinding systems wherever possible.
>
> The player must be able to visit another village, interact with its residents, investigate its businesses, and return home.
>
> Do not introduce automatic teleportation or fast travel without separate owner approval.
>
> PHASE 3 — MAYORAL ENVOY SYSTEM
>
> Implement recurring economic survey missions organized by the mayor or current legitimate village leadership.
>
> Envoys are physical NPCs operating within the existing world.
>
> They must travel to other settlements, gather information, return home, and report their findings.
>
> Envoy assignment
>
> Village leadership periodically evaluates which known settlements need surveying.
>
> Consider:
>
> - Time since the last survey.
> - Availability of envoys.
> - Distance and travel requirements.
> - Known economic opportunities.
> - Whether contact has previously been established.
> - The need to discover additional settlements.
>
> Use the existing NPC occupation, scheduling, and leadership systems where practical.
>
> Avoid creating an unnecessarily separate simulation framework.
>
> Visiting another village
>
> Upon arriving at a settlement, the envoy must systematically attempt to meet with every accessible business owner and independent crafter.
>
> Do not replace individual surveys with a magical village-wide inventory lookup.
>
> Each meeting must gather available information about:
>
> - Goods produced.
> - Goods currently available for sale.
> - Quantities available.
> - Asking prices.
> - Goods or materials needed.
> - Quantities wanted.
> - Offered purchasing prices.
> - Tools, supplies, and production requirements.
> - Known future shortages or surpluses.
> - Relevant production capacity, when available.
>
> The information must originate from the actual NPC's inventory, needs, production, business records, and willingness to trade.
>
> Record which NPC provided the information and when it was collected.
>
> Distinguish confirmed information from estimates, unknown information, and refused interviews.
>
> A business owner who is absent, unavailable, or unwilling to speak should not be silently treated as successfully surveyed.
>
> The envoy should follow believable daily schedules and travel behavior.
>
> Returning home
>
> After completing the survey, the envoy physically returns to their home village.
>
> The gathered information must not become available to the home village before the envoy communicates it through an actual supported mechanism.
>
> Upon returning, the envoy reports to the mayor or legitimate leadership.
>
> The envoy then performs the same detailed survey of home-village businesses and independent craftspeople.
>
> This is essential: both villages must be evaluated using actual economic information.
>
> Recurring surveys
>
> Information becomes outdated as goods are produced, consumed, purchased, and sold.
>
> Envoys must revisit settlements and refresh their records.
>
> Determine a sensible survey frequency based on travel time, NPC availability, and the age of information.
>
> Do not assume the same frequency is appropriate for every settlement.
>
> Investigate whether merchants, travelers, and other NPCs can contribute legitimate economic information without replacing the envoy system.
>
> PHASE 4 — ECONOMIC INFORMATION NETWORK
>
> Create a persistent, provenance-aware system for communicating economic opportunities.
>
> An envoy's report should contain information about specific individuals and businesses, not merely generic village-wide supply and demand totals.
>
> For example:
>
> Smith A in Village A needs 25 iron ingots.
>
> Smith B in Village B reports 40 iron ingots available for sale.
>
> The envoy establishes that this potential connection exists.
>
> The information should reach the relevant NPCs through appropriate village communication mechanisms.
>
> Do not grant every NPC instantaneous knowledge of all markets.
>
> NPCs should know:
>
> - Who may have the goods they need.
> - Where that person or business is located.
> - Reported quantities.
> - Reported prices, if available.
> - When the information was collected.
> - Whether contact has previously occurred.
>
> Information must be capable of becoming outdated.
>
> An NPC should not assume a reported quantity is still available indefinitely.
>
> PHASE 5 — INDEPENDENT NPC TRADE DECISIONS
>
> OWNER-APPROVED RULE: THE ENVOY DOES NOT ARRANGE THE TRANSACTION.
>
> The envoy creates economic awareness.
>
> The individual business owner or crafter decides whether to act.
>
> For example:
>
> 1. Smith A learns that Smith B has iron available.
> 2. Smith A evaluates whether he needs the iron.
> 3. Smith A considers the price, available funds, distance, and expected benefit.
> 4. Smith A independently decides whether to initiate contact.
> 5. If interested, Smith A uses the actual game's communication, travel, or merchant mechanisms to reach Smith B.
> 6. The two parties negotiate quantity, price, and terms.
> 7. If both agree, a legitimate transaction occurs.
> 8. Goods and money move through the appropriate existing systems.
>
> No forced purchases.
>
> No automatic contracts created by the envoy.
>
> No centrally assigned trade partners.
>
> No instant inventory transfers between villages.
>
> Use the existing flexible procurement-contract model wherever possible.
>
> A contract may specify an item, quantity, unit price, and negotiated terms.
>
> Independent miners, farmers, blacksmiths, craftspeople, merchants, and other producers must retain their individual economic agency.
>
> Trade must respect ownership, inventory availability, purchasing power, transportation, and economic integrity.
>
> NPCs may reject opportunities or negotiate different terms.
>
> PHASE 6 — REGIONAL DEMAND AND BUSINESS FOUNDING
>
> Revisit the existing 35% worker-utilization threshold.
>
> We have observed workers operating at approximately 2–20% utilization, with no new business founding.
>
> Do not assume the threshold is wrong.
>
> Determine whether low utilization reflects:
>
> - Genuine lack of demand.
> - Missing external village demand.
> - Poor communication of available opportunities.
> - Insufficient purchasing power.
> - Inaccessible markets.
> - Production or inventory imbalances.
> - Missing trade routes.
> - Defective demand calculations.
> - Existing businesses meeting all actual needs.
>
> Investigate whether legitimate external demand can increase worker utilization and create opportunities for new businesses.
>
> External demand must only count as economically meaningful when there is a plausible way to satisfy it.
>
> A shortage in a distant, unreachable village should not automatically create profitable demand in the home village.
>
> Account for transportation, price, quantity, available labor, and actual buyer interest.
>
> Do not artificially force business founding.
>
> Business founding should emerge from real economic opportunities and NPC decisions.
>
> Also investigate the previously identified household first-tool purchasing and retiree inventory issues, preserving ownership and accounting integrity.
>
> PHASE 7 — SIMULATION, PERFORMANCE AND ECONOMIC INTEGRITY
>
> Extend the relevant validation and reporting systems to measure the regional economy.
>
> Required measurements include:
>
> - Number of generated villages.
> - Number of reachable villages.
> - Settlements discovered by players and NPCs.
> - Envoy assignments, departures, arrivals, interviews, returns, and reports.
> - Survey coverage by village.
> - Age and accuracy of economic information.
> - Trade opportunities identified.
> - Opportunities pursued or rejected by NPCs.
> - Negotiations and completed contracts.
> - Goods transported between settlements.
> - Money exchanged.
> - Regional supply and demand.
> - Worker utilization before and after external trade becomes available.
> - Business founding attributable to legitimate regional demand.
> - Failed journeys and unreachable destinations.
> - Population and economic changes over time.
> - CPU and memory impact.
> - Save/load and deterministic replay integrity.
>
> Ensure that goods and money are conserved.
>
> Prevent duplicate inventory transfers, invented currency, and double-counted demand.
>
> Verify that envoys and merchants cannot create or destroy resources through travel, interruption, death, save/load, or failed transactions.
>
> Test situations where reported goods are sold before a buyer arrives.
>
> Test villages with no viable trade opportunities.
>
> Test leadership succession while envoy missions are active.
>
> Test NPCs who refuse interviews or transactions.
>
> Test routes that become inaccessible.
>
> Use focused simulations to investigate behavior before expensive full-year campaigns.
>
> PHASE 8 — DEVELOPMENT EXECUTION AND RELEASE PROTECTION
>
> The existing Build 25 candidate is frozen at commit "4b51c92".
>
> Two authorized 365-day campaigns are running against that commit.
>
> Do not modify the frozen candidate, interrupt those campaigns, or initiate duplicate year-long simulations.
>
> Create a separate, clearly identified development branch for the regional economy and world-navigation work.
>
> First complete the architecture audit and establish the dependencies between the systems.
>
> Then prepare an implementation plan based on the verified codebase.
>
> You are authorized to proceed with focused, reversible implementation of the owner-approved behavior described here when the architecture and correctness requirements are established.
>
> However, stop and request a decision before implementing any major design choice not resolved by this directive, particularly changes to core world topology, political authority, fast travel, economic ownership, or fundamental NPC autonomy.
>
> Do not substitute simplified or simulated-only behavior for the required actual in-world systems merely to make tests pass.
>
> Keep implementation work isolated from Build 25.
>
> Use focused tests during development and reuse existing passing CI evidence for unchanged commits.
>
> Do not launch new long-duration campaigns, merge into the frozen release branch, package, or publish without authorization.
>
> PHASE 9 — PERMANENT PROJECT RECORDS
>
> Document:
>
> - Original design intent.
> - Current architecture and observed deficiencies.
> - Root causes of missing village discovery or regional demand.
> - Owner-approved behavioral rules.
> - Major technical decisions and why they were made.
> - Implemented changes.
> - Rejected alternatives and supporting evidence.
> - Test results and measured performance.
> - Unresolved questions and investigations.
> - Dependencies and future development phases.
>
> Follow our permanent GitHub project documentation and decision-history standards.
>
> Ensure a future Claude or ChatGPT conversation can reconstruct the project's status, decisions, and reasoning directly from the repository.
>
> REQUIRED REPORTING
>
> Provide an initial architecture and gap report after inspecting the existing systems.
>
> Then proceed through implementation in coherent stages, reporting meaningful milestones without repeatedly stopping for minor technical decisions already covered by this directive.
>
> When development reaches a genuine owner-level design decision, present the options, consequences, evidence, and recommendation.
>
> The final report must establish whether:
>
> 1. Multiple villages are physically generated and reachable.
> 2. The player can discover and navigate between them.
> 3. The world map accurately reflects the playable region.
> 4. Envoys physically travel and survey individual businesses.
> 5. Reports reach home leadership and relevant economic participants.
> 6. NPCs independently initiate contact and negotiate trades.
> 7. Goods and money move correctly between villages.
> 8. Regional demand influences business decisions appropriately.
> 9. Economic integrity and deterministic simulation remain intact.
> 10. The systems operate acceptably on Android and desktop.
>
> FINAL DIRECTIVE
>
> This is a living-world simulation, not a collection of disconnected village economies.
>
> We want individual villagers making decisions based on information they realistically acquire, actual needs, available resources, and economic opportunities.
>
> The envoy discovers the opportunity. The business owner decides whether to pursue it. The parties negotiate. The world carries out the transaction.
>
> Investigate thoroughly, implement carefully, verify every important assumption, and document why the system works.
>
> Proceed.
