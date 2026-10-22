# Owner decisions, 2026-10-23: Build 18 decision package B18-DP-01..14

Saved by the lead from the owner's message of 2026-10-23 (the full text as given in the session; headings and lists kept).
Register: B18-DP-01..14 and the records they name.

---

MY MEDIEVAL LIFE — BUILD 18
Owner Decision Package: B18-DP-01 Through B18-DP-14
This is my consolidated response to the Build 18 decision package dated October 23, 2026.
These decisions resolve the 14 owner-level questions in that package. Apply them to the requirements register, implementation plan, and release checklist.

Governing instructions
* Preserve previously approved design decisions unless explicitly modified below.
* Apply MSW-01: Minimum Sufficient Work.
* Apply RCA-01: Root Cause Before Workaround.
* Reuse existing economic, employment, production, contract, inventory, and NPC systems wherever possible.
* Do not introduce arbitrary restrictions, artificial population caps, resource creation, or unexplained economic behavior.
* Do not silently remove approved requirements. Record anything deferred, its destination build, and any dependencies.
* These decisions are not authorization to expand Build 18 indefinitely.
* Do not package Build 18 until the required functionality and pre-package verification are complete. A candidate package for my mandatory device playtest is permitted when those conditions are met.
* Do not interpret a decision requiring implementation as evidence that implementation or testing has already passed.

B18-DP-01 — Player Businesses, Employees, and Contracted Services
OWNER DECISION: BOTH PERMANENT EMPLOYMENT AND CONTRACTED SERVICES MUST BE AVAILABLE.
These are two separate economic relationships, not merely different levels of automation.
A. Permanent employment
A player must be able to offer an NPC ongoing employment through the existing job-offer and wage systems.
Examples include: Hiring a miner to work a mine. Hiring a blacksmith to operate a forge. Hiring a carpenter to manufacture goods. Hiring an attendant to operate a shop or market stall. Hiring a worker to perform an assigned production role.
Permanent employment must follow the established employment framework, including job acceptance, wages, working hours, worker availability, workplace access, production requirements, and termination.
A worker should continue performing the assigned job during normal simulation operation, subject to actual resources, equipment, conditions, and wages.
C. Contracted services
A player must also be able to negotiate a specific task or quantity of work without permanently employing the NPC.
For example, I may contract a miner to produce or deliver 50 iron ore for an agreed payment.
The contract must specify the relevant task or deliverable, quantity where applicable, payment, and completion conditions using existing contract conventions.
The NPC remains an independent contractor rather than becoming a permanent employee.
Contracts must represent actual economic activity. Signing a contract must not generate free materials, bypass travel or labor requirements, or guarantee resources that cannot realistically be obtained.
Build 18 implementation direction
First audit what already exists.
The decision package reports that hired attendants, wages, and business stages 1–4 already exist, but production-chain integration, stall displays, and shops in leased village houses remain incomplete.
Complete those previously approved Build 18 elements using existing systems:
1. Attendants operate applicable workshop stations using real recipes, materials, and wages.
2. Produced goods can be stocked and sold through the player's business.
3. Stalls display goods using existing item icons.
4. Leased village houses can operate as shops under existing lease and storefront rules.
Separately verify which general-purpose employment and service-contract capabilities already exist.
Both employment models are permanent design requirements. However, do not invent a completely new universal contracting framework under Build 18 merely because I clarified that both models must eventually be available.
If general-purpose mining contracts or other contracted labor are not already supported or assigned to Build 18, document the precise missing functionality and propose the appropriate later implementation phase without silently dropping the requirement.
No simulation progress occurs while the game is closed.
Acceptance: Distinguish clearly between an ongoing employee and a contracted worker, identify which workflows are functional, and demonstrate real production, payment, and inventory conservation.

B18-DP-02 — Expandable Property
APPROVED: Recommendation.
Retain the existing expandable-property implementation. A player may begin with a basic structure and expand the same property over time without demolishing the original building. The previously approved doorway and relaid-plot solution, ROOMS-18, resolves the identified design question. Do not add NPC household expansion behavior merely to close this requirement. Verify the system during playtesting.

B18-DP-03 — Modular House and Workshop Expansion
APPROVED: Recommendation.
Maintain connected additions for workshops, storage, living quarters, and other supported facilities. The same property may support mixed residential and commercial functions. Preserve working doors, navigation, roofs, walls, and production stations. No profession-based restriction should prevent a player from using a supported room or workstation. Separate signs for every module are not required. Do not add unrelated building features. Close DP-02 and DP-03 after their existing functionality passes the appropriate checks and owner playtest.

B18-DP-04 — Farming, Livestock, and Ploughs
OWNER DECISION: KEEP WHAT IS NECESSARY TO MAKE BUILD 18 FUNCTIONAL. DEFER THE REMAINDER.
Do not expand Build 18 into a complete farming and livestock feature release. Preserve and verify the already functional farming loop, including the existing hand plough and approved horse plough. Maintain whatever planting, growing, harvesting, animal, and resource behavior is necessary for the current economy and gameplay to function correctly. Do not introduce a Farming skill gate that prevents basic work. Existing skills may improve efficiency. Purchased seeds and other traded goods should come from real inventory where the current economic system supports that requirement.
The following may be deferred where they are not dependencies of the functional Build 18 simulation: Additional coops and shelters. Expanded trapping mechanics. Additional animal-purchasing interfaces. Expanded watering interactions. Hired farmhands. Other incomplete livestock features that are not necessary for Build 18 stability.
Important: A deferred feature must remain an open, traceable requirement, not be marked complete. Audit the actual dependencies before deferring anything. If a feature is required for existing animals or farms to survive and operate, retain the minimum working implementation. Report the precise list of retained and deferred features and assign the deferred work to an appropriate later build.

B18-DP-05 — Settlement Development
APPROVED: Recommendation, with a verification clarification.
Settlements must grow, decline, and specialize through the same underlying economic and demographic rules as the village, at the appropriate off-map level of detail. Use existing systems for: Households entering trades with sustained unmet demand. Businesses losing workers and closing when appropriate. Production capacity responding to available labor. Population and employment changes. Natural resource, labor, and economic constraints. Do not impose arbitrary settlement population caps. Do not add an entirely new off-map housing inventory model for Build 18.
Verification correction: A 365-day simulation is a one-year simulation, not a multi-generation simulation. Run the appropriate 100-day and 365-day stability and economic checks for Build 18. If the approved settlement-development requirement specifically requires multi-generation verification, either provide a genuinely sufficient simulation horizon or retain that verification item as outstanding. Do not label one year as multiple human generations.

B18-DP-06 — Economic Consequences
APPROVED: Recommendation.
No new mechanic is authorized here. Use the existing economy and complete the required evidence. Compare the 100-day and 365-day results, including: Supply and shortages. Prices and availability. Employment and production. Trade. Household and business wealth. Scarcity-driven NPC behavior. Produce the written scarcity-response audit. Close WDR-004-C only when the verification supports it.

B18-DP-07 — NPC Self-Improvement and Prosperity
OWNER DECISION: OPTION B — MOVE THIS SYSTEM TO BUILD 19.
Do not implement a temporary aspiration model in Build 18. NPC aspirations should be designed alongside the Build 19 personality, judgment, relationship, and decision-making systems. The five approved aspiration domains remain requirements: 1. Food and personal security. 2. Money and wealth. 3. Goods and property. 4. Professional development. 5. Family and household development. Priorities must eventually respond to actual circumstances, successes, setbacks, and opportunities. The aspiration system should influence meaningful decisions rather than exist as decorative statistics. Preserve the original requirement and its acceptance criteria, but reassign implementation to Build 19. Do not create a disposable Build 18 implementation that must later be replaced. This is an explicit owner-approved deferral and must not block Build 18.

B18-DP-08 — NPC Competition and Economic Rivalry
APPROVED: Recommendation.
Use the existing economic rules to complete the missing competition behaviors. Craftspeople should favor products that produce better returns under actual local demand and prices. Employers facing labor shortages may offer higher wages within the established wage system. Businesses may relocate to better available stalls where existing location and demand mechanics support that decision. Businesses can fail when they cannot operate economically. NPC businesses and player businesses follow the same economic principles. Do not provide the player artificial market preference. Avoid implementing a new economy or complex speculative behavior model. Use focused verification for specialization, hiring competition, and relocation.

B18-DP-09 — Stone Dressing Efficiency and Materials
APPROVED: Recommendation.
Use the existing Masonry skill and crafting conventions. Base dressing conversion: 3 raw stone input. 2 dressed stone blocks. 1 unit of recoverable rubble or raw stone fragments. The fragments remain usable as raw stone where the existing material rules allow. Skill affects efficiency through the existing Masonry tiers and crafting conventions. Do not add an unrelated skill system or a separate profession-title production bonus. Use dressed blocks for new structural masonry and raw stone for repairs and hearths where appropriate. Where the current building system cannot reliably distinguish routine maintenance from structural reconstruction, retain the existing functioning behavior. Maintain material conservation and test the relevant production paths.

B18-DP-10 — Iron Chisel
APPROVED: Recommendation.
Use the existing tool and smithing conventions. Recipe: forge_chisel. Station: anvil. Materials: 1 iron bar. Production time: 30 minutes. Required Smithing level: 1. Durability: 150 dressings. Wear: 1 use per dressing. Value: follow the existing forged-tool valuation convention, approximately equivalent to the hammer where justified. The chisel must be a real, physically conserved inventory item. It must be manufactured, acquired, used, and consumed through the existing economy. Do not add special Masonry wear savings unless already supported by the relevant skill convention. Verify tool wear, inventory conservation, crafting, and save compatibility.

B18-DP-11 — Chapel Artwork
APPROVED: Recommendation.
Distinct chapel artwork is not a Build 18 release blocker. If an already-owned compatible asset provides an appropriate sign, bell-cote, or chapel distinction, use it when practical. Do not initiate a major art search, purchase, or new asset-production effort just to close this item. The current small-house artwork is acceptable for Build 18 if no suitable existing asset is available. Retain future visual improvements as polish work.

B18-DP-12 — Player Volunteering at the Chapel
APPROVED: Recommendation.
The player must be able to volunteer on the church field under the same applicable rules as NPC villagers. Preserve player/NPC parity. Reuse the existing volunteering, farming, and church systems. Do not create a separate special-case player activity when the NPC behavior can be shared. Verify that the player can perform the activity and that its results are handled consistently.

B18-DP-13 — Courier Fees and Contract Signing Threshold
APPROVED: Recommendation.
Retain the provisional Build 18 fee coefficients and the 50-coin formal-signing threshold. These are acceptable initial balance values, not immutable long-term rules. Do not reopen the economic model to rebalance these values before Build 18 playtesting. Ensure fees, payments, and transfers remain consistent with the existing conservation rules. Revisit balance after actual gameplay evidence.

B18-DP-14 — Different Settlement Profiles
APPROVED: Recommendation.
All settlements operate under the same underlying economic rules. Their individual identities and economic profiles must emerge from actual differences in: Resources. Population. Available skills and workers. Existing businesses. Local supply and demand. Trade relationships. Economic opportunities and constraints. Do not assign arbitrary economic personalities or special advantages merely to make settlements look different. Distinct outcomes should emerge from the simulation. This confirms the existing interpretation of Q18-6.

Implementation and Verification Instructions
1. Update the requirements register. Record all 14 decisions. Distinguish among: Approved and already implemented. Approved but awaiting implementation. Awaiting verification. Explicitly deferred to Build 19 or another later build. Permanently blocked with owner acceptance, if applicable. Do not mark an untested feature complete.
2. Preserve Build 18 scope. My decisions on DP-04 and DP-07 explicitly reduce the remaining Build 18 scope. My DP-01 decision establishes that both permanent employment and contracted services belong in the game, but does not automatically authorize building a new general-purpose contract engine before Build 18. Use the existing approved Build 18 requirements to determine what must ship now.
3. Continue parallel development. Do not interrupt workers unnecessarily. Integrate these decisions into the existing workstreams and avoid duplicate implementation. Continue the approved simulation, economic, UI, save, and regression work.
4. Run release verification. Before presenting Build 18 as ready for my device playtest, complete the applicable: Functional and regression tests. Economic conservation checks. Determinism checks. Save/load and migration checks. Required simulation-duration checks. Platform build and launch checks. Requirement and dependency audits. Do not claim that a test passed until its result is available.
5. Report back concisely. Provide: 1. Confirmation that all 14 decisions were recorded. 2. The actual existing employment and service-contract capabilities, especially whether I can hire a miner permanently or contract for a defined quantity of ore. 3. The precise Build 18 farming features retained and deferred. 4. Confirmation that NPC aspirations moved to Build 19. 5. Remaining Build 18 blockers, separated into implementation, verification, and owner decisions. 6. The next concrete steps toward a playable Build 18 candidate.

Final direction: Finish the approved, functional Build 18 with the minimum sufficient work. Preserve the larger game design without forcing every future system into this release. Do not reopen these decisions unless implementation reveals a genuine conflict that cannot be resolved under the existing approved rules.
