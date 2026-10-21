# Owner directive, 2026-10-21: Build 17 architecture, mining, contracts and outstanding decisions

Received in the session on 2026-10-21, verbatim:

> HOT ATTIC GAMES — MY MEDIEVAL LIFE
>
> MASTER DEVELOPMENT DIRECTIVE
>
> Build 17 Architecture, Mining Expansion, Economic Contracts, and Outstanding Owner Decisions
>
> Project: My Medieval Life
> Repository: "verbal76/My-Medieval-Life"
> Build 16 integration branch: "staging/my-medieval-life"
> Build 17 planning branch: "wip/build17-plan"
> Last reported Build 17 planning commit: "375b855"
> Priority: Continue Build 16 development while resolving Build 17 architecture and design questions.
>
> ---
>
> 1. PRIMARY OBJECTIVE
>
> This directive consolidates the owner's decisions concerning Build 17 mining, underground environments, resource sustainability, employment contracts, economic proposals, and the DVW-A12 architectural refactor.
>
> These decisions are intended to establish the correct long-term direction of My Medieval Life without interfering with active Build 16 development.
>
> This is one complete authoritative instruction. Do not require separate amendments to interpret the decisions contained here.
>
> The objectives are to:
>
> 1. Record and preserve all owner-approved decisions.
> 2. Translate approved gameplay rules into clear engineering requirements.
> 3. Investigate the appropriate architecture for caves, underground mining, and open-pit excavation.
> 4. Preserve existing resource sustainability mechanics across every mining environment.
> 5. Define the architecture for universal negotiated goods-procurement contracts.
> 6. Prepare the DVW-A12 refactor for controlled implementation.
> 7. Retrieve and explain four outstanding economic proposals.
> 8. Continue all previously approved Build 16 development.
> 9. Preserve GitHub branches, current progress, and release boundaries.
>
> Do not mistake architectural approval for permission to begin an entire unapproved expansion.
>
> ---
>
> 2. CURRENT DEVELOPMENT STATE AND AUTHORITY
>
> The most recent report stated that:
>
> - Four Build 16 implementation workers remained active.
> - Build 17 read-only planning was saved to "wip/build17-plan".
> - The reported planning commit was "375b855".
> - Build 17 planning was isolated from Build 16 staging.
> - DVW-A12 was partially implemented.
> - The current world architecture used a flat navigation, movement, and collision model.
>
> These are last-reported facts, not independently verified current conditions.
>
> Check the repository before making new claims about progress.
>
> Historical documents
>
> The owner has supplied numerous historical specifications, Build 10 and Build 11 punch lists, world design rules, and expansion plans.
>
> These documents explain the game's design evolution.
>
> They are not automatically current defect lists.
>
> Do not assume an old problem remains unresolved merely because it appears in an earlier build document.
>
> Use this authority order:
>
> 1. Latest explicit owner decisions.
> 2. Current verified implementation and authoritative requirements.
> 3. Recent approved development instructions.
> 4. Historical design specifications and prior decisions, where not superseded.
> 5. Engineering recommendations, clearly labeled as proposals.
>
> Preserve enduring design principles unless the owner has explicitly revised them.
>
> Do not reopen completed historical work without current evidence.
>
> ---
>
> 3. OWNER DECISION 1 — CAVES, UNDERGROUND MINING, AND MAP DEPTH
>
> Approved visual and gameplay direction
>
> The owner wants genuine, enterable underground environments.
>
> These include:
>
> - Natural caves.
> - Underground mining passages.
> - Excavated tunnels.
> - Chambers and irregular rock formations.
> - Open-pit mining environments.
> - Eventually, industrial mining infrastructure.
>
> The owner supplied a visual reference showing an irregular, atmospheric cave environment.
>
> That screenshot is a conceptual reference, not an art asset or an instruction to reproduce its appearance.
>
> All cave environments must match My Medieval Life's established isometric perspective, character scale, sprite presentation, and art direction.
>
> Cave appearance
>
> Caves should look naturally formed rather than like rectangular rooms or conventional dungeon corridors.
>
> They may contain:
>
> - Irregular passage widths.
> - Winding routes.
> - Narrow openings.
> - Larger chambers.
> - Uneven walls.
> - Natural rock formations.
> - Exposed mineral deposits.
> - Darker areas requiring illumination.
> - Mining equipment and structural supports where appropriate.
>
> The result should feel like a natural part of the existing world.
>
> Roof and overhead visibility
>
> The owner specifically referenced the existing house-interior behavior.
>
> When the player enters a house, its roof disappears or becomes transparent so the interior can be seen.
>
> Caves should use a comparable visual principle.
>
> When the player enters an underground area, overhead terrain or rock should disappear, become transparent, or otherwise stop obstructing the character and immediate playable environment.
>
> The player must remain visible and able to navigate.
>
> Lighting and darkness should contribute to atmosphere without making the game unplayable.
>
> This does not mean the existing house-roof implementation automatically solves underground navigation.
>
> Investigate whether its rendering approach can be reused.
>
> Functional requirements
>
> Underground environments must eventually support:
>
> - Player movement.
> - NPC movement and pathfinding.
> - Mining and resource extraction.
> - Real resource depletion.
> - Equipment and inventory interaction.
> - Transport of extracted materials.
> - Access between surface and underground areas.
> - Save/load persistence.
> - Consistent world simulation.
> - Future mining infrastructure.
>
> Do not implement a purely decorative pit as a substitute for the approved long-term design.
>
> Architectural investigation
>
> The previous report offered two alternatives:
>
> Option A — Single-layer visual excavation
>
> Represent pits using the existing flat navigation layer.
>
> Advantages may include lower immediate development cost.
>
> Limitations include restricted genuine elevation and underground behavior.
>
> Option B — Separate underground maps
>
> Represent underground environments as separate maps connected by entrances.
>
> Advantages may include isolated navigation and scene management.
>
> Limitations may include transition handling, persistence, and synchronization.
>
> The owner and design collaborator also identified a third option requiring investigation:
>
> Option C — Multiple logical elevation layers
>
> Maintain connected surface and underground environments through separate logical elevation, navigation, collision, and rendering layers.
>
> This may offer greater long-term flexibility but could require substantial architectural changes.
>
> Required investigation
>
> Compare all three approaches using actual repository evidence.
>
> Evaluate:
>
> 1. Godot implementation feasibility.
> 2. Current movement and collision dependencies.
> 3. NPC pathfinding and scheduling.
> 4. Rendering and roof transparency.
> 5. Surface-to-underground transitions.
> 6. Save compatibility.
> 7. Performance on Android, Windows, Linux, and Steam Deck.
> 8. Existing map-generation dependencies.
> 9. Support for open-pit excavation.
> 10. Future minecarts, tunnels, shafts, and industrial mining.
> 11. Implementation complexity.
> 12. Migration and regression risks.
>
> Current owner decision
>
> The desired gameplay and visual behavior is approved. The exact technical architecture is not yet selected.
>
> The preferred direction to investigate is a layered-world approach.
>
> However, do not treat this preference as authorization to undertake an unnecessary engine rewrite.
>
> If separate underground maps can provide equivalent player-facing behavior with significantly lower technical risk, present that evidence.
>
> Recommend the architecture that best supports the long-term game at a reasonable engineering cost.
>
> Do not silently defer approved mining features merely because the current architecture is flat.
>
> If a feature requires later scheduling, explain the dependency and request the necessary scheduling decision.
>
> ---
>
> 4. OWNER DECISION 2 — UNIVERSAL MINERAL DEPOSIT SUSTAINABILITY
>
> Approved rule
>
> Mineral deposits use the same resource objects and sustainability mechanics regardless of their location.
>
> A mineral deposit discovered:
>
> - On the surface,
> - Inside an open-pit mine,
> - Inside a natural cave,
> - Inside an excavated tunnel,
>
> must follow the same underlying resource rules.
>
> The owner specifically expects the recognizable ore-bearing rock with visible mineral dots to appear in these environments.
>
> Implementation requirements
>
> Reuse the authoritative existing mineral-deposit system.
>
> Preserve:
>
> - Resource identity.
> - Visual mineral indicators.
> - Extraction requirements.
> - Available quantities.
> - Depletion behavior.
> - Sustainability or replenishment behavior, if applicable.
> - Inventory transfers.
> - Save/load persistence.
> - Resource accounting.
>
> Do not create a second resource economy specifically for underground mining.
>
> Do not automatically regenerate underground deposits unless that behavior is already part of the approved common deposit system.
>
> Do not assume that every deposit is permanently exhaustible without verifying the current authoritative sustainability rules.
>
> Required action
>
> Inspect the existing surface deposit implementation.
>
> Document how sustainability currently works and identify what must be reused or adapted for caves and pits.
>
> The owner's decision is mechanical consistency across environments, not a newly approved depletion formula.
>
> If the existing sustainability policy contains unresolved decisions, identify them separately.
>
> ---
>
> 5. OWNER DECISION 3 — UNIVERSAL NEGOTIATED PROCUREMENT CONTRACTS
>
> Core design principle
>
> The owner does not want mining to have a unique, hard-coded wage system.
>
> Instead, the game should support a general-purpose contract mechanism through which one character can offer another character payment for a specified quantity of a specified product.
>
> This applies to mining, farming, forestry, crafting, and other tradable goods.
>
> Independent workers
>
> A character working independently may gather or produce resources for personal needs, household use, business production, or resale.
>
> If the character sells those goods, payment depends on what an actual buyer is willing and able to pay.
>
> No automatic wage is generated merely because a resource was extracted.
>
> Contracted workers
>
> When a character wants to hire another character to supply goods, the contract should support three primary configurable terms:
>
> 1. Product or item.
> 2. Quantity required.
> 3. Payment per unit.
>
> The buyer must be able to change these values.
>
> Owner-provided example
>
> A player approaches an NPC and initiates conversation using the normal interaction control.
>
> The player offers:
>
> 70 wheat at 2 gold per unit.
>
> The total agreed contract value would be 140 gold.
>
> The same system should support an offer for iron nuggets, planks, stone, or any other eligible tradable item.
>
> The product must not be restricted to the worker's nominal profession unless actual skill, equipment, availability, or feasibility constraints make fulfillment impossible.
>
> Conversation integration
>
> The existing game already includes work-related conversations in which NPCs may offer the player jobs.
>
> The owner wants comparable flexibility when the player initiates an offer to another character.
>
> For example, the player should be able to select an NPC, initiate conversation, and propose a goods-procurement contract.
>
> Reuse the established interaction framework rather than creating an unrelated employment interface.
>
> Contract negotiation
>
> A proposed contract is an offer, not an automatic command.
>
> NPCs should be able to evaluate:
>
> - Whether they can obtain or produce the requested item.
> - Whether they have the necessary skills and tools.
> - Whether the quantity is feasible.
> - Whether the price is worthwhile.
> - Their existing obligations.
> - Household needs.
> - Available time.
> - Competing economic opportunities.
> - Their relationship with the buyer.
> - Relevant risk and uncertainty.
>
> An NPC may accept, reject, or counteroffer.
>
> Do not make NPCs automatically agree simply because the player offered money.
>
> Player and NPC parity
>
> The underlying contract system should be reusable for:
>
> - Player hiring NPC.
> - NPC hiring player.
> - NPC hiring another NPC.
>
> These arrangements should obey the same economic and inventory rules.
>
> Economic conservation
>
> A contract must not create free goods or money.
>
> Actual fulfillment requires actual goods.
>
> Payments must be backed by legitimate funds or explicitly supported credit arrangements.
>
> Prevent duplicated deliveries, duplicate payment, negative inventory, and contradictory ownership transfers.
>
> Important unresolved implementation details
>
> The owner has approved the general contract model, but has not yet selected every contract-policy detail.
>
> Do not silently establish permanent rules for:
>
> - Advance payment versus payment on delivery.
> - Partial delivery.
> - Deadlines.
> - Cancellation.
> - Default and breach.
> - Escrow or reserved funds.
> - Whether delivery must occur all at once.
> - Contract renegotiation after acceptance.
>
> Inspect existing contract and job systems first.
>
> Reuse existing approved behavior where compatible.
>
> If a genuine new owner decision is required, present the current behavior, options, consequences, and recommendation.
>
> Implementation scope
>
> This is a cross-system economic capability, not simply a mining feature.
>
> Investigate how it aligns with the existing job system and the planned Living Economy expansion.
>
> Do not introduce a competing contract architecture that will later need replacement.
>
> Do not insert the entire system into Build 16 without verifying that it belongs to the approved Build 16 scope.
>
> ---
>
> 6. OWNER DECISION 4 — DVW-A12 RULES-TO-CORE REFACTOR
>
> Approved direction
>
> The owner agrees with the recommendation to move gameplay rules out of interface code.
>
> Claude previously reported that this refactor was partially completed and that some audit line references were outdated.
>
> Priority systems
>
> The recommended order is:
>
> 1. Mining.
> 2. Felling.
> 3. Crafting.
>
> This order is approved as an engineering direction, subject to current code dependencies.
>
> Implementation requirements
>
> The interface should primarily handle presentation, input, and feedback.
>
> Authoritative gameplay systems should own:
>
> - Eligibility and action validation.
> - Resource requirements.
> - Resource consumption.
> - Action outcomes.
> - Inventory and currency transfers.
> - Relevant game-state changes.
>
> Avoid duplicate business rules in UI components.
>
> Regression safeguards
>
> Preserve existing behavior unless an independently approved requirement explicitly changes it.
>
> Test:
>
> - Player interactions.
> - NPC interactions.
> - Tool requirements.
> - Resource consumption.
> - Inventory changes.
> - Action completion and failure.
> - Save/load.
> - Deterministic behavior.
> - Relevant controller and touch input.
>
> Do not perform a broad speculative rewrite.
>
> Use small, reviewable changes with focused tests.
>
> Scheduling authorization
>
> The architectural direction is approved.
>
> However, Build 16 remains the immediate implementation priority.
>
> Before Build 16's automated completion gate, DVW-A12 work should remain planning and preparation unless the current authoritative Build 16 scope independently authorizes a specific change.
>
> Once Build 17 implementation is permitted, carry out the refactor in isolated branches with appropriate regression testing.
>
> Do not destabilize the frozen Build 16 candidate.
>
> ---
>
> 7. OUTSTANDING ECONOMIC DECISIONS — INFORMATION REQUIRED
>
> Four economic proposals remain unresolved:
>
> - ECON-P1.1
> - ECON-P1.2
> - ECON-P1.4
> - ECON-P1.5
>
> The owner has not approved or rejected these proposals.
>
> The previous report did not provide enough information for an informed decision.
>
> Required response for each proposal
>
> Retrieve the exact authoritative proposal and provide the following:
>
> A. Original question
>
> What is the actual decision requiring owner approval?
>
> B. Current implementation
>
> How does the game handle this situation today?
>
> Identify the relevant systems, source files, and current behavior.
>
> C. Proposed change
>
> What would change if the proposal were approved?
>
> Explain the actual mechanic rather than merely repeating a requirement identifier.
>
> D. Available alternatives
>
> Provide practical choices, including retaining current behavior when applicable.
>
> E. System-wide consequences
>
> Explain how the proposal may affect:
>
> - NPC decision-making.
> - Households.
> - Employment.
> - Resource availability.
> - Production.
> - Market prices.
> - Trade.
> - Money conservation.
> - Inventory conservation.
> - Manor finances.
> - Long-term economic equilibrium.
>
> F. Engineering consequences
>
> Identify relevant dependencies, migration requirements, testing needs, and implementation risks.
>
> G. Recommendation
>
> Provide a technically justified recommendation.
>
> Explain why it is preferable to the alternatives.
>
> Presentation requirements
>
> Keep all four questions separate.
>
> Use plain language understandable to the owner without requiring source-code familiarity.
>
> Distinguish:
>
> - Verified current behavior.
> - Existing approved design.
> - Historical proposals.
> - New engineering recommendations.
> - Genuine unresolved decisions.
>
> Do not implement the proposals while awaiting approval.
>
> Do not infer their contents from their identifiers.
>
> Return them as clear, specific questions the owner can answer individually.
>
> ---
>
> 8. BUILD 16 DEVELOPMENT MUST CONTINUE
>
> The most recent report identified four active Build 16 workers.
>
> Do not interrupt their approved development to perform this planning exercise.
>
> Continue:
>
> - Family farming and land systems.
> - Market stalls and commerce.
> - Cattle and seasonal farming investigations.
> - Remaining approved Build 16 requirements.
> - Integration and regression testing.
> - Simulation validation.
> - Git preservation.
>
> The lead integration manager should continue reviewing and integrating completed worker changes.
>
> Do not leave productive workers idle because an unrelated Build 17 question remains unresolved.
>
> If a specific Build 16 task is blocked, move to another approved independent task.
>
> Build 16 release gate
>
> Preserve the previously established requirements:
>
> - Complete approved implementation.
> - Integrate on staging.
> - Validate current-SHA tests.
> - Verify deterministic simulation.
> - Preserve money and inventory conservation.
> - Verify save compatibility.
> - Validate Android, Windows, and Linux exports.
> - Prepare the private owner-playtest candidate.
>
> Do not merge into production or publish a final release without explicit owner approval.
>
> ---
>
> 9. GITHUB BRANCHING AND PRESERVATION
>
> GitHub remains the authoritative remote development workspace.
>
> The Build 17 plan was reportedly pushed to:
>
> "wip/build17-plan"
>
> at commit:
>
> "375b855"
>
> Verify these references before updating the plan.
>
> Branch requirements
>
> - Keep Build 17 planning isolated from Build 16 staging.
> - Do not merge planning changes into staging for convenience.
> - Preserve completed planning through commits and remote pushes.
> - Record exact commit SHAs.
> - Keep implementation workers isolated by branch and file ownership.
> - Do not overwrite active work.
> - Do not confuse local branches with remotely preserved GitHub work.
>
> Update the Build 17 plan to reflect the decisions in this directive.
>
> A documentation-only update to the planning branch is authorized.
>
> No new Build 17 gameplay implementation is authorized solely by this directive.
>
> ---
>
> 10. DESIGN INTEGRITY AND LONG-TERM ARCHITECTURE
>
> My Medieval Life is intended to become a living, interconnected simulation.
>
> The player is one participant in that world, not the sole reason the world functions.
>
> NPCs must have meaningful autonomy.
>
> Resources and money must have actual ownership and consequences.
>
> Economic decisions should emerge from needs, opportunities, limitations, and competing priorities.
>
> Architectural principle
>
> Do not select a short-term implementation merely because it is easy if it creates a major foreseeable obstacle to the approved long-term design.
>
> At the same time, do not undertake an unnecessarily expensive rewrite when a simpler architecture can achieve the same functional result.
>
> Present genuine tradeoffs.
>
> Avoid speculative systems that duplicate existing mechanics.
>
> Preserve the established world-design rules and Interlocking Systems Manifest where applicable.
>
> Long-term integration
>
> The following systems are expected to interact eventually:
>
> - Mining and geological discovery.
> - Settlement industrial capabilities.
> - NPC skills and employment.
> - Negotiated procurement contracts.
> - Adaptive markets.
> - Regional trade.
> - Household needs.
> - Manor finances.
> - Resource sustainability.
> - Subjective NPC judgment and decision-making.
>
> Do not attempt to implement all of these systems simultaneously.
>
> Design interfaces that support future integration without prematurely expanding the current build.
>
> ---
>
> 11. REQUIRED RESPONSE TO THE OWNER
>
> After recording the decisions and updating the isolated Build 17 plan, provide a concise but substantive report.
>
> Part A — Decisions recorded
>
> Confirm:
>
> 1. Cave and underground visual/gameplay requirements.
> 2. Deposit sustainability consistency.
> 3. Universal negotiated goods contracts.
> 4. DVW-A12 architectural direction.
>
> Identify the exact GitHub commit containing the updated planning documents.
>
> Part B — Underground architecture comparison
>
> Present the three architecture alternatives with:
>
> - Feasibility.
> - Development cost and risk.
> - Player-facing differences.
> - Long-term limitations.
> - Save and navigation consequences.
> - Recommended option.
>
> Clearly identify any remaining owner choice.
>
> Part C — Four economic proposals
>
> Provide the complete decision breakdown for ECON-P1.1, ECON-P1.2, ECON-P1.4, and ECON-P1.5.
>
> Do not substitute brief labels for explanations.
>
> Part D — Build 16 progress
>
> Report the latest available:
>
> - Staging SHA.
> - Active worker status.
> - Completed integrations.
> - Test results.
> - Simulation findings.
> - Genuine blockers.
>
> Do not manufacture results if workers are still running.
>
> Part E — Next authorized actions
>
> Identify what can proceed without additional approval and what remains gated.
>
> Do not ask the owner to reapprove decisions already settled in this directive.
>
> ---
>
> 12. FINAL EXECUTION INSTRUCTION
>
> Immediately perform the following authorized work:
>
> 1. Verify the current GitHub state.
> 2. Update the isolated Build 17 planning documents with the owner decisions.
> 3. Investigate the three underground architecture alternatives.
> 4. Document the existing deposit sustainability system and how it can be reused.
> 5. Map the universal contract requirements to existing job and economic systems.
> 6. Record the approved DVW-A12 refactor direction and safeguards.
> 7. Retrieve the four outstanding ECON proposals and prepare detailed owner decision briefs.
> 8. Commit and push the planning updates to the remote Build 17 planning branch.
> 9. Continue all independent, approved Build 16 implementation and integration work without interruption.
> 10. Return the requested decision report.
>
> Do not begin unapproved Build 17 gameplay implementation.
>
> Do not reopen previously settled owner decisions.
>
> Do not turn historical punch lists into current development blockers without verification.
>
> Do not pause Build 16 while preparing Build 17.
>
> Do not publish a release or merge into production without explicit approval.
>
> The objective is to preserve the owner's long-term design, eliminate ambiguity, support informed decisions, and keep productive development moving.
>
> Begin the authorized planning and ongoing development work now.
