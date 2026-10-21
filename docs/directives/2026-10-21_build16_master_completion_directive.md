# Owner directive, 2026-10-21: complete Build 16, verify the expansion, transition to Build 17

Received in the session on 2026-10-21, verbatim:

> MY MEDIEVAL LIFE
>
> MASTER DEVELOPMENT DIRECTIVE
>
> Complete Build 16, Verify the Expansion, and Transition to Build 17
>
> Priority: Immediate
> Project: My Medieval Life
> Repository: "verbal76/My-Medieval-Life"
> Integration branch: "staging/my-medieval-life"
> Owner availability: Approximately 10–12 hours before hands-on playtesting is possible
>
> ---
>
> 1. PRIMARY OBJECTIVE
>
> Complete the entire approved Build 16 expansion as quickly as sound engineering permits.
>
> This is not a request for another audit-only session, another planning cycle, or a small development candidate in place of the actual expansion.
>
> The objective is to finish Build 16 in full.
>
> I am unavailable for hands-on playtesting for approximately the next 10–12 hours. This is an opportunity to make substantial progress without interruption.
>
> It is not a requirement to consume that entire period.
>
> If Build 16 is completed in three hours, excellent. Move immediately into the authorized transition activities.
>
> If it requires longer, continue development until the approved requirements are complete.
>
> Do not sacrifice functionality, deterministic behavior, resource conservation, or testing quality to meet an arbitrary deadline.
>
> Do not stop productive work merely because I am unavailable.
>
> Standing development rules
>
> 1. Continue approved development without repeatedly requesting permission.
> 2. Preserve completed work through Git commits and remote pushes.
> 3. Do not leave the main development session idle when independent work remains.
> 4. Do not expand the Build 16 feature scope without authorization.
> 5. Do not silently defer approved Build 16 requirements.
> 6. Do not treat an incomplete development candidate as the completed expansion.
> 7. Do not merge into production or publish a final release without explicit owner approval.
> 8. Do not start Build 17 implementation in a way that delays or destabilizes Build 16.
> 9. Report actual results, not optimistic estimates.
> 10. Maintain one authoritative source of truth for development status.
>
> ---
>
> 2. CURRENT BASELINE
>
> The most recent Build 16 audit reported:
>
> Status| Count
> Complete and verified| 41
> Implemented, awaiting verification| 21
> In progress| 17
> Not started| 22
> Blocked| 2
> Superseded| 2
> Total registered| 105
>
> That represents 41 verified items out of 103 nonsuperseded items, approximately 40%.
>
> The reported staging HEAD was "c63dc28", with "02ae508" as the latest code-changing commit at the time of the audit.
>
> These figures are a starting reference, not an assumption about the current repository state.
>
> Before assigning work:
>
> - Read the current authoritative Build 16 register.
> - Verify the actual staging HEAD.
> - Check current GitHub Actions results.
> - Identify completed work that has not yet been reflected in the register.
> - Identify any active or abandoned agent worktrees.
> - Preserve all verified changes.
>
> Do this efficiently. Do not repeat the previous comprehensive audit unnecessarily.
>
> The approved Build 16 scope is the existing register, updated by the explicit owner decisions in this directive.
>
> ---
>
> 3. DEVELOPMENT ORGANIZATION
>
> Use a coordinated parallel-development structure.
>
> The lead Claude session acts as the integration manager.
>
> Initially use up to four independent implementation workers, if the execution environment supports that level of concurrency safely.
>
> These are maximum initial allocations, not a requirement to keep agents running unnecessarily.
>
> Lead integration manager
>
> The lead owns:
>
> - Critical-path planning.
> - Task allocation.
> - Shared architecture.
> - Interface agreements.
> - Git integration.
> - Conflict resolution.
> - Regression testing.
> - Simulation orchestration.
> - Release readiness.
> - Development status.
> - Owner reporting.
>
> The lead must not spend the entire session writing status reports while workers develop the game.
>
> Integrate verified work continuously.
>
> Worker A — Family farms and land ownership
>
> Primary responsibility:
>
> - FARM-01 through FARM-07.
> - Variable farmland placement.
> - Land leasing.
> - Outright land purchasing.
> - Plot clearing and construction.
> - Fencing and gates.
> - Sowing and harvesting.
> - Household farming labor.
> - Related land planning and requirements.
>
> Worker B — Market stalls and commerce
>
> Primary responsibility:
>
> - STALL-01 through STALL-06.
> - Stall construction.
> - Stocking and inventory.
> - Player and NPC sales.
> - Unattended operation.
> - Closing and reopening.
> - Settlement.
> - Universal commission.
> - Treasury integration.
>
> Worker C — Farming balance, cattle, and food security
>
> Primary responsibility:
>
> - FARM-08.
> - FARM-08A/B/C as applicable.
> - FSE-12.
> - FSE-13.
> - Livestock sustainability.
> - Grain accessibility.
> - Seasonal farming.
> - Yield comparisons.
> - Milk production.
> - Food-security regression testing.
>
> Worker D — Remaining independent Build 16 work
>
> Primary responsibility:
>
> - REC-001.
> - DVW-A5.
> - Remaining parity and conservation defects.
> - Outstanding independent equilibrium requirements.
> - Incomplete seed and merchant verification.
> - Acceptance-test infrastructure.
> - Other independent Build 16 register items.
>
> The lead must assign exact item IDs, dependencies, and file ownership rather than allowing workers to choose overlapping work.
>
> Git isolation
>
> Each worker uses a separate Git worktree and development branch.
>
> Each worker must:
>
> 1. Start from a known staging commit.
> 2. Work only within its assigned scope.
> 3. Coordinate shared-file changes with the lead.
> 4. Add focused tests.
> 5. Run applicable local verification.
> 6. Commit completed work.
> 7. Push the branch to GitHub.
> 8. Report the commit SHA and results.
> 9. Hand integration ownership back to the lead.
>
> The lead reviews and integrates completed work incrementally.
>
> Do not allow simultaneous uncontrolled writes to the same staging branch.
>
> Do not spawn nested agents without authorization.
>
> If four workers create more integration overhead than productive progress, reduce concurrency.
>
> ---
>
> 4. OWNER DECISIONS — ALL SIX LAND AND STALL QUESTIONS RESOLVED
>
> The following decisions are final owner instructions for Build 16.
>
> They supersede conflicting recommendations in earlier reports.
>
> Record Q8 through Q13 as resolved.
>
> Q8 — Five-percent stall commission accounting
>
> Approved: retain fractional commission remainders in accounting.
>
> The manor receives 5% of actual completed stall sales.
>
> Use an exact deterministic accounting method compatible with the existing currency model.
>
> Do not repeatedly round individual transactions in a way that creates or destroys money.
>
> Do not introduce freely spendable fractional coins unless the existing economy supports them.
>
> Maintain conservation of the actual currency supply.
>
> Q9 — Farmland fence and gate materials
>
> Approved: use existing animal-pen recipes plus stone.
>
> Inspect the existing animal-pen construction recipes.
>
> Reuse their established material requirements and add stone consistently.
>
> The required quantity of fence construction must be determined by the actual selected plot perimeter.
>
> Gate placement and construction must follow existing building and access rules.
>
> Materials must be taken from real inventory.
>
> No free construction resources.
>
> If the exact stone increment is not already defined, use the established construction quantity convention where applicable; otherwise identify the smallest unresolved numeric decision without blocking unrelated work.
>
> Q10 — Market stall construction
>
> Approved: three planks per stall.
>
> Use the established construction system and actual material consumption.
>
> The completed stall must be a functioning economic object, not merely decorative scenery.
>
> Q11 — Variable farmland plots, leasing, and outright purchase
>
> Approved: adjustable rectangular land selection with area-based pricing.
>
> The placement interaction should follow the existing green-square house-plot workflow, adapted for adjustable farmland.
>
> Placement
>
> 1. The player begins farmland placement.
> 2. The player places the first green corner marker.
> 3. The player drags diagonally toward the opposite corner.
> 4. The rectangular selection grows or shrinks dynamically.
> 5. The selected area determines the actual farmland boundaries.
> 6. The placement preview indicates whether the location is valid.
> 7. The player must explicitly confirm the transaction.
>
> The size is not restricted to a fixed 5×6 rectangle.
>
> Use the existing world grid and land-ownership systems.
>
> Prevent overlapping ownership, inaccessible placements, and invalid terrain.
>
> Dynamic price display
>
> As the player drags the second corner, display the calculated financial obligation prominently near the center of the screen.
>
> The displayed amount must update immediately with plot size.
>
> The player must be able to see the cost before confirming.
>
> Support two transaction modes:
>
> Lease: recurring weekly payment to the manor.
>
> Purchase: outright payment to acquire the applicable land rights.
>
> Larger plots must have higher lease prices and higher outright purchase prices than smaller plots.
>
> Pricing
>
> The previous approved 2-coin weekly lease is the reference for the earlier baseline plot.
>
> It is not a universal flat price for every plot size.
>
> First inspect existing land-area, lease, and purchase conventions.
>
> Use an existing authoritative area-based pricing formula if one exists and is compatible with this design.
>
> If no such formula exists, develop a clearly documented deterministic proposal for both weekly lease and outright purchase.
>
> Do not invent an undisclosed multiplier, reference plot area, or purchase-to-lease ratio.
>
> If a new numeric pricing policy requires owner approval, implement the placement UI, area calculations, transaction interfaces, and tests independently, then isolate the unresolved coefficient for approval.
>
> Do not silently finalize an arbitrary economic policy.
>
> Ownership
>
> Leased plots incur the applicable weekly payment.
>
> Purchased plots do not continue incurring a weekly lease for that same land.
>
> All payments transfer real currency to the manor.
>
> Insufficient funds prevent purchase or lease confirmation.
>
> NPC households use the same underlying pricing and ownership rules.
>
> NPC land selection must reflect actual resources, household needs, and available land.
>
> No special free-land privileges for NPCs or the player.
>
> Q12 — Commission applies to all stalls
>
> Approved: ALL market stalls pay the 5% commission.
>
> This includes:
>
> - Player stalls.
> - NPC stalls.
> - Existing merchant stalls.
> - Newly constructed stalls.
>
> Audit existing pitch fees and settlement behavior.
>
> Ensure the universal commission applies consistently.
>
> Do not accidentally charge duplicate commissions.
>
> Preserve other preexisting legitimate charges unless an actual conflict requires resolution.
>
> Q13 — Stall proceeds require closure
>
> Approved: sellers must close their stalls to access outstanding profits.
>
> While a stall is open, its unsettled sales proceeds are not available for withdrawal.
>
> Closing a stall initiates settlement.
>
> Settlement must:
>
> 1. Reconcile actual completed sales.
> 2. Calculate the manor's 5% commission.
> 3. Transfer commission proceeds to the manor.
> 4. Release the seller's net outstanding profits.
> 5. Preserve unsold merchandise.
> 6. Record the transaction accurately.
> 7. Maintain conservation.
>
> A seller may immediately reopen the stall after settlement.
>
> When a stall sells out, it closes automatically and settles its proceeds.
>
> No withdrawing unsettled profits from an open stall.
>
> ---
>
> 5. MANOR TREASURY — THE VILLAGE FINANCIAL RESERVE
>
> This is a fundamental economic requirement.
>
> The manor acts as the village's bank-like treasury and financial reserve.
>
> Money collected by the manor does not disappear from the game economy.
>
> Legitimate manor income includes applicable:
>
> - Land lease payments.
> - Outright land purchases.
> - Stall commissions.
> - Existing taxes and fees.
> - Other established manor revenue.
>
> The manor uses actual available funds to participate in the village economy.
>
> Economic circulation
>
> The intended economic loop is:
>
> Villagers and businesses earn money through real economic activity.
>
> They pay legitimate fees and obligations to the manor.
>
> The manor accumulates those funds in its treasury.
>
> During shortages or economic slowdowns, the manor can purchase real supplies from actual sellers.
>
> Those purchases return currency to the economy.
>
> The purchased goods become actual manor inventory.
>
> The manor can then use legitimately owned supplies through the existing relief system.
>
> Conservation requirements
>
> - No money generation.
> - No free supplies.
> - No fictitious stock.
> - No unlimited treasury.
> - No invisible subsidies.
> - No unaccounted transfers.
> - No duplication through commission settlement.
> - No relief distributions without actual inventory.
>
> Inspect and reuse the existing manor treasury, procurement, storage, and relief systems.
>
> Do not create a parallel treasury that bypasses established accounting.
>
> Preserve existing approved relief rules.
>
> If a new reserve threshold, purchase priority, or spending policy is necessary and no approved policy exists, document the decision rather than inventing a permanent economic rule.
>
> Implement all independently approved treasury integration immediately.
>
> ---
>
> 6. FAMILY FARMING COMPLETION
>
> Complete the family-farming expansion as a functioning gameplay system.
>
> It must include, as applicable to the approved Build 16 register:
>
> - Variable plot dimensions.
> - Actual land ownership or lease records.
> - Real recurring lease obligations.
> - Outright purchase.
> - Actual clearing.
> - Perimeter-based fencing.
> - Gates and access.
> - Plowing.
> - Sowing.
> - Seasonal crop behavior.
> - Seed inventory consumption.
> - Harvesting.
> - Household labor.
> - Actual produce ownership.
> - Storage and food use.
> - NPC household decisions.
> - Player/NPC mechanical parity.
>
> NPC households must not receive free land, free seeds, free materials, or artificial crop yields.
>
> Farm viability must be measured under the actual economy.
>
> Integrate with the existing seed merchant, seed recovery, seasonal calendar, and conservation systems.
>
> ---
>
> 7. MARKET STALL COMPLETION
>
> Complete STALL-01 through STALL-06 as actual economic gameplay.
>
> Stalls must support:
>
> - Construction using three planks.
> - Ownership.
> - Real stocked inventory.
> - Actual buyer transactions.
> - NPC and player sellers.
> - Unattended operation where previously approved.
> - Automatic closure on sellout.
> - Manual closure.
> - Close-to-settle accounting.
> - Immediate reopening.
> - Universal 5% manor commission.
> - Actual net profits.
> - Preservation of unsold goods.
> - Treasury integration.
> - Conservation.
> - Deterministic transaction behavior.
>
> Verify the behavior of existing merchant stalls under the new universal commission.
>
> Avoid creating duplicate sales systems when existing authoritative trading code can be reused.
>
> ---
>
> 8. CATTLE AND SEASONAL FARMING
>
> The cattle investigation remains a critical Build 16 workstream.
>
> However, it must not prevent unrelated family-farm or market-stall development.
>
> Known findings
>
> Earlier comparisons indicated:
>
> - Shared farming alone did not produce the same cattle collapse.
> - Seasonal farming created early grain-supply gaps.
> - Cattle could lose access to feed even while the manor held grain.
> - Keepers sometimes could not purchase suitable quantities from available sellers.
> - Herds could fall below breeding viability.
> - Milk production collapsed with the herd.
>
> These are investigation findings, not permission to introduce artificial fixes.
>
> Required resolution
>
> Identify and distinguish:
>
> - Legitimate seasonal shortages.
> - Grain accessibility defects.
> - Seller and buyer quantity restrictions.
> - Feed scheduling problems.
> - Trough refill problems.
> - Grazing and pasture behavior.
> - Reproduction constraints.
> - Age-related deaths.
> - Population recovery.
>
> Correct actual defects.
>
> Do not solve the problem by spawning cattle or food.
>
> Do not secretly subsidize farmers.
>
> Do not weaken the conservation system.
>
> Yield selection
>
> Finish the available FARM-08 comparisons.
>
> Recommend an appropriate yield based on:
>
> - Food security.
> - Seasonal supply.
> - Livestock survival.
> - Seed sustainability.
> - Manor production.
> - Family farm viability.
> - Market availability.
> - Economic balance.
>
> Do not globally enable FSE-12 or FSE-13 or choose a permanent yield without the required owner approval.
>
> If the unresolved balance decision is the only remaining blocker to final completion, present the exact evidence and a concise decision request.
>
> Continue independent approved work in the meantime.
>
> ---
>
> 9. REMAINING BUILD 16 REQUIREMENTS
>
> Complete every other mandatory approved item in the authoritative register.
>
> This includes remaining work in:
>
> - Food security.
> - Household behavior.
> - Adoption and guardianship.
> - Player/NPC parity.
> - Seed propagation.
> - Seed merchants.
> - Armorer and shop counters.
> - Need-based trade.
> - Caravan purchasing.
> - Witness-based crime reporting.
> - Resource conservation.
> - Time and calendar consistency.
> - Equilibrium.
> - Economic stability.
> - Acceptance testing.
>
> Do not infer that a feature is complete merely because its main code exists.
>
> Check its acceptance criteria.
>
> Armorer and trade counters
>
> The prior audit reported that the armoury counter was implemented and passed automated tests.
>
> Preserve and verify:
>
> - The appropriate smith/armorer production capability.
> - Functional counter interaction.
> - Press A to request service.
> - Available shopkeeper travels to the counter.
> - Shopkeeper schedules and availability.
> - Actual goods and inventory.
> - Real currency exchange.
> - Need-based input purchasing.
> - Player/NPC parity.
>
> The owner's device playtest remains an acceptance step.
>
> Do not falsely report device validation before it occurs.
>
> ---
>
> 10. TESTING STRATEGY
>
> Quality assurance must operate continuously alongside development.
>
> Stage A — Focused worker tests
>
> Each worker tests the changed system before handoff.
>
> Use targeted deterministic tests to catch failures quickly.
>
> Do not use full-year simulations as the first test of a simple code change.
>
> Stage B — Integration tests
>
> After merging verified worker changes into staging:
>
> - Run all applicable Godot suites.
> - Run Python tests.
> - Run determinism checks.
> - Check script errors.
> - Verify save/load.
> - Check cross-system inventory transfers.
> - Check currency conservation.
> - Check resource conservation.
> - Verify interface compatibility.
>
> A failure must be attributed to the relevant change and corrected.
>
> Stage C — Simulation tests
>
> Use multiple deterministic seeds.
>
> Test normal gameplay and relevant experimental configurations separately.
>
> Verify:
>
> - Household food security.
> - Crop production.
> - Seed availability.
> - Livestock feed.
> - Livestock reproduction.
> - Milk production.
> - Trade availability.
> - Manor treasury behavior.
> - Market stall settlement.
> - Land lease collection.
> - Household economic viability.
> - Population behavior.
> - Conservation.
> - Long-term stability.
>
> Do not conflate a passing simulation on an old commit with validation of new code.
>
> Stage D — Build verification
>
> For the release candidate:
>
> - Verify Android export.
> - Verify Windows export.
> - Verify Linux export.
> - Verify startup.
> - Verify save migration.
> - Verify actual artifact commit SHA.
> - Document known limitations.
>
> The Android signing-key difference is not a priority concern for me at this time.
>
> I am the sole playtester.
>
> Do not spend significant time on signing-key research unless it becomes a genuine blocker.
>
> Do warn before any action that could destroy existing save data.
>
> ---
>
> 11. BUILD 16 COMPLETION CRITERIA
>
> Build 16 is implementation-complete only when:
>
> 1. All mandatory approved Build 16 features are implemented.
> 2. All required automated tests pass.
> 3. The systems are integrated on staging.
> 4. Determinism remains valid.
> 5. Coin and item conservation are maintained.
> 6. No unresolved critical script errors remain.
> 7. Farming and livestock systems meet approved acceptance criteria.
> 8. Family farms function.
> 9. Market stalls function.
> 10. The manor treasury operates consistently.
> 11. Save/load and migration work.
> 12. Platform exports succeed.
> 13. The authoritative register accurately reflects completion.
> 14. All unresolved mandatory owner decisions are explicitly identified and resolved before final acceptance.
>
> Do not change acceptance criteria merely to obtain a passing result.
>
> Do not remove required tests.
>
> Do not declare untested features verified.
>
> Distinguish:
>
> - Implementation complete.
> - Automated verification complete.
> - Private release candidate ready.
> - Owner playtest pending.
> - Final owner acceptance.
>
> These are separate statuses.
>
> ---
>
> 12. RELEASE AND ARTIFACT POLICY
>
> The objective is a complete Build 16 release candidate for private playtesting.
>
> You may continue the previously authorized private development-candidate workflow and prepare private artifacts.
>
> Use the established release pipeline where possible.
>
> Do not publish a public release.
>
> Do not merge into the production branch without approval.
>
> Do not mark Build 16 as owner-accepted without my review.
>
> If all automated checks pass while I am unavailable, prepare the private Build 16 candidate and provide the artifacts through an access-controlled method.
>
> If final publication or merge requires approval, leave it ready and request that approval.
>
> Do not confuse preparing a candidate with publishing the final release.
>
> ---
>
> 13. BUILD 17 — CONTROLLED EARLY PREPARATION
>
> Build 17 must not interfere with Build 16 completion.
>
> However, when Build 16 development reaches a stage where workers are waiting on integration, testing, or simulation results, useful Build 17 preparation may proceed.
>
> Build 16 always has priority.
>
> Authorized Build 17 activity before Build 16 is complete
>
> Read-only work is permitted, including:
>
> - Reviewing existing Build 17 requirements.
> - Inspecting relevant architecture.
> - Mapping dependencies.
> - Identifying interfaces likely to change.
> - Reviewing existing tests.
> - Identifying technical debt.
> - Preparing a Build 17 implementation plan.
> - Producing a risk register.
> - Identifying opportunities for safe parallel implementation.
> - Preparing test specifications.
> - Reviewing the deferred DVW-A12 UI rules-to-core refactor.
> - Reviewing other items explicitly assigned to Build 17 in the authoritative register.
>
> Do not invent a new Build 17 feature list.
>
> Use the existing approved Build 17 scope.
>
> Strict isolation
>
> Build 17 preparation must:
>
> - Be read-only against Build 16 source code.
> - Avoid modifying shared runtime systems.
> - Avoid changing Build 16 acceptance criteria.
> - Avoid modifying staging.
> - Avoid interfering with active Build 16 workers.
> - Avoid monopolizing scarce CI capacity.
> - Avoid consuming resources needed for Build 16 critical-path work.
>
> If documentation needs to be saved, use a separate Build 17 planning branch or isolated documentation area.
>
> No Build 17 planning commit should be merged into Build 16 staging merely for convenience.
>
> Resource allocation
>
> Do not reserve a worker exclusively for Build 17 while Build 16 implementation work remains available.
>
> Build 17 read-only preparation may use otherwise idle capacity when it demonstrably does not delay Build 16.
>
> If Build 16 requires the resources, stop or suspend the Build 17 preparation immediately.
>
> After Build 16 automated completion
>
> Once Build 16 is implementation-complete, integrated, and passes its automated release gate:
>
> 1. Freeze the Build 16 release-candidate commit.
> 2. Record its exact SHA.
> 3. Prepare the private candidate for owner playtesting.
> 4. Preserve a clean Build 16 release path.
> 5. Continue Build 17 planning on a separate branch.
>
> If owner playtesting is the only remaining Build 16 acceptance step, Build 17 implementation may begin only for independently approved and fully specified work, on an isolated Build 17 branch, provided the Build 16 release candidate remains frozen and immediately available for fixes.
>
> Do not merge Build 17 code into Build 16.
>
> Do not begin unapproved Build 17 features.
>
> Do not publish Build 17.
>
> If owner playtesting reveals a Build 16 defect, prioritize fixing that defect before further Build 17 development.
>
> ---
>
> 14. DEVELOPMENT EFFICIENCY AND RESOURCE MANAGEMENT
>
> We are currently under our weekly usage cap.
>
> The owner reports approximately 25% weekly usage consumed with roughly 43–44% of the weekly period elapsed.
>
> Therefore, productive development throughput is more important than extreme token minimization.
>
> However, avoid waste.
>
> Agent efficiency
>
> Use agents for:
>
> - Independent substantial implementation.
> - Focused cross-system investigations.
> - Isolated testing tasks.
> - Work that benefits from genuine parallel execution.
>
> Do not use large agents merely to:
>
> - Copy numbers from logs.
> - Repeat completed audits.
> - Reformat status documents.
> - Search for a single known symbol.
> - Duplicate another worker's investigation.
>
> Use scripts and existing tooling for mechanical extraction.
>
> RTK
>
> Check whether RTK is operating correctly.
>
> The prior audit reported substantial historical savings but warned that its hook was not installed.
>
> Correct a genuine missing hook if it can be done safely and quickly.
>
> Do not turn RTK configuration into a major distraction from Build 16.
>
> Continuous work
>
> The previous audit identified an avoidable idle period of approximately six hours and fifteen minutes.
>
> Do not repeat that.
>
> When blocked:
>
> 1. Identify the specific dependency.
> 2. Preserve current work.
> 3. Assign an independent approved task.
> 4. Continue productive development.
> 5. Return to the blocked task when the dependency resolves.
>
> Do not create unnecessary work merely to appear active.
>
> ---
>
> 15. OWNER DECISIONS AND BLOCKERS
>
> Maintain a concise decision register.
>
> Every unresolved question must identify:
>
> - Item ID.
> - Exact decision required.
> - Existing relevant mechanic.
> - Available options.
> - Recommendation.
> - What work is blocked.
> - What work can continue.
>
> Q8 through Q13 are resolved by this directive.
>
> Do not ask those questions again.
>
> Do not reopen approved decisions without evidence of a genuine technical contradiction.
>
> Previously approved Build 17 and Build 18 deferrals remain in effect.
>
> Do not pull deferred features into Build 16.
>
> For OD-17, present the exact existing hero, view, and Steam Deck questions from the authoritative record when owner input becomes necessary.
>
> Do not fabricate answers.
>
> If the owner is unavailable, continue independent approved work.
>
> ---
>
> 16. PROGRESS REPORTING
>
> At the beginning of execution, provide a brief operational plan identifying:
>
> - Current staging SHA.
> - Worker assignments.
> - Isolated branch names.
> - Critical path.
> - Current blockers.
> - Integration order.
> - Test plan.
>
> Then begin implementation.
>
> Do not wait for another approval to perform already-approved work.
>
> Provide concise progress reports at meaningful milestones, not after every small code change.
>
> Maintain the authoritative Build 16 register.
>
> When an item becomes verified, record the evidence.
>
> When a test fails, report the actual failure.
>
> When a worker finishes, integrate or reassign appropriately.
>
> Do not substitute reports for development.
>
> ---
>
> 17. REQUIRED END-OF-PUSH REPORT
>
> When the coordinated push reaches its next major completion milestone, report:
>
> Build 16
>
> - Total registered items.
> - Verified items.
> - Remaining incomplete items.
> - Actual completion percentage.
> - Current staging SHA.
> - Integrated worker commits.
> - Automated test results.
> - Simulation results.
> - Remaining defects.
> - Outstanding owner decisions.
> - Android, Windows and Linux artifact status.
> - Private release-candidate readiness.
> - Required owner playtests.
>
> Development efficiency
>
> - Workers used.
> - Major completed tasks.
> - Parallel work that saved time.
> - Integration conflicts.
> - Failed or wasted runs.
> - Measured usage, if available.
>
> Build 17
>
> - Approved Build 17 scope identified.
> - Read-only audits completed.
> - Architecture and dependency findings.
> - Risks.
> - Suggested implementation order.
> - Any isolated approved work begun after the Build 16 release-candidate freeze.
>
> Do not report Build 17 preparation as Build 16 progress.
>
> ---
>
> 18. FINAL EXECUTION INSTRUCTION
>
> The priority order is:
>
> FIRST: Complete the approved Build 16 implementation.
>
> SECOND: Integrate and verify the complete expansion.
>
> THIRD: Prepare the private Build 16 release candidate for my playtesting.
>
> FOURTH: Preserve the release candidate and prepare Build 17.
>
> FIFTH: Begin only independently approved Build 17 implementation when Build 16's automated completion gate has passed and Build 16 remains protected from interference.
>
> Build 16 must not be delayed by Build 17.
>
> Build 17 preparation should use otherwise idle capacity, not compete with Build 16's critical path.
>
> Do not intentionally consume the full 10–12-hour window.
>
> Do not rush unfinished work into a release.
>
> Do not stop development just because I cannot playtest yet.
>
> Do not claim that 40% completion means the remaining work will be quick.
>
> Do not manufacture progress.
>
> The objective is maximum verified development progress, full Build 16 completion, and a clean, controlled transition to Build 17.
>
> Start the coordinated development push now.
