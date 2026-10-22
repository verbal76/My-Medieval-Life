# Owner directive, 2026-10-21: Build 17 Owner Decisions — Consolidated Implementation Directive (MIN-D, MIN-E, MIN-C, CON02-S)

Saved verbatim from the owner's message (CLAUDE.md section 9a). Note on numbering: the directive's MIN-E items map to the
register by content: its MIN-E-Q1 = MIN-E-Q1 (earth reuse); MIN-E-Q2 = MIN-STONE-Q/STONE-01; MIN-E-Q3 = MIN-D-Q3;
MIN-E-Q4 (shovels) = MIN-E-Q2 ("spade"); MIN-E-Q5 (rights) = MIN-E-Q3; MIN-E-Q6 (specialists) = MIN-E-Q4; MIN-E-Q7
(larger pits) = MIN-E-Q5.

---

MY MEDIEVAL LIFE — BUILD 17 OWNER DECISIONS
Consolidated Implementation Directive
Project: My Medieval Life
Developer: Hot Attic Games
Repository: `verbal76/My-Medieval-Life`
Primary branch: `wip/build17`
Authority: Owner-approved decisions
Scope: MIN-D, MIN-E, MIN-C, CON02-S
Status: Design decisions approved. Implementation and verification remain subject to the requirements below.
1. MANDATORY INSTRUCTIONS
Claude, this document records the owner's answers to the remaining 14 questions reviewed for Build 17.
Treat these answers as binding design decisions.
Your responsibilities are to:

1. Record every decision in the appropriate requirements register, decision ledger, and supporting documentation.
2. Reconcile each decision with existing implementation and earlier owner directives.
3. Identify what is already implemented, what requires changes, and what belongs in a future build.
4. Preserve working Build 17 functionality and established simulation invariants.
5. Create properly tracked requirements for deferred features.
6. Implement only the changes appropriate to Build 17 without expanding its scope unnecessarily.
7. Preserve determinism, save compatibility, and conservation.
8. Report any genuine conflicts or unresolved implementation parameters.
9. Do not reinterpret approved decisions as optional suggestions.
10. Do not release, publish, or merge into a release branch without explicit owner authorization.

Governing principle:
A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
This means:

* No artificial resource creation.
* No disappearing goods or currency without a legitimate accounted process.
* No automatic subsidies.
* No guaranteed employment or contracts.
* No guaranteed successful discoveries.
* No automatic ownership or extraction rights.
* No teleportation of physical goods.
* No artificial demand introduced merely to keep the economy active.
* No NPC behavior that exists solely to force a desired outcome.
* No arbitrary player/NPC rule differences.

NPCs must remain independent decision-makers operating within the same underlying simulation rules as the player.
2. MIN-D-Q2 — PLAYER CONTRIBUTION TO SETTLEMENT CAPABILITY
OWNER DECISION: APPROVED
Count the player as a resident under exactly the same mining-capability rules as NPC villagers, including relevant skills and equipment.
Required behavior
If the player resides in a settlement, their relevant mining capabilities must contribute to that settlement's capability calculation.
Apply the same eligibility and contribution rules to:

* The player.
* Resident miners.
* Resident prospectors.
* Other relevant resident workers.

Relevant factors may include actual skills, usable equipment, and legitimate access to facilities, according to the established capability system.
Restrictions

* The player's equipment remains the player's property.
* Counting equipment does not transfer ownership to the settlement.
* The player's skill does not automatically become another miner's skill.
* The player must not receive an artificial capability bonus.
* The player must not be excluded merely because they are player-controlled.
* Capability calculations must remain deterministic.
* Capability levels must not become permission gates, consistent with Q18-9.

If the player leaves the settlement or no longer satisfies the applicable resident criteria, recalculate their contribution under the same rules used for NPCs.
Implementation
Update the capability evaluation and its tests where appropriate.
Confirm that equivalent player and NPC circumstances produce equivalent capability contributions.
3. MIN-D-Q3 — RECOVERABLE TRIAL-PIT MATERIALS
OWNER DECISION: APPROVED
Trial pits must produce conserved, recoverable excavated spoil and topsoil.
These materials must support:

* Physical storage.
* Hauling.
* Reuse.
* Disposal.

Required behavior
Trial-pit excavation must generate recoverable material representing the earth physically removed.
The resulting quantities must be consistent with the excavation model.
Integrate trial pits with the established MIN-E material system rather than introducing incompatible parallel inventories.
Preserve the existing distinction between topsoil, subsoil/dirt, and rocky spoil where the excavation layers support that distinction.
Conservation requirements
Excavation transfers material from the ground into recoverable inventory or physical storage.
Hauling moves material between locations.
Backfilling transfers suitable material back into excavated space.
Legitimate consumption, processing, or disposal must be explicitly represented and accounted for.
No operation may silently create or destroy inventory.
Integration
Coordinate with:

* MIN-E open pits.
* MIN-F underground excavation.
* Physical hauling.
* Storage and stockpiles.
* Player-directed tunnel backfilling.
* Economy conservation ledgers.
* Save/load serialization.

Previously approved underground backfilling remains player-directed only.
Do not introduce automatic NPC tunnel backfilling.
4. MIN-E-Q1 — PRACTICAL REUSE OF EXCAVATED EARTH
OWNER DECISION: APPROVED
Allow practical reuse of excavated topsoil, dirt, and spoil for:

1. Farmland improvement.
2. Road embankments.
3. Grading building plots.
4. Defensive earthworks.
5. Landscaping.

Required behavior
These must be genuine physical construction or land-improvement processes.
Each process requires appropriate:

* Material quantities.
* Material suitability.
* Transport.
* Tools.
* Labor.
* Time.
* Construction or agricultural mechanics.

Farming
Topsoil may improve farmland through a legitimate soil-improvement process.
Do not create an unexplained permanent yield bonus merely because topsoil exists in inventory.
Actual improvement must require applying appropriate material to the land.
Roads
Road construction and embankments may consume suitable excavated earth.
Roads must be physically constructed and integrated with the future road and settlement-expansion systems.
Building sites
Grading must involve legitimate earthmoving and construction work.
Defensive earthworks
Earthworks may include appropriate defensive terrain improvements when the relevant systems exist.
Landscaping
Landscaping must represent actual changes to terrain or land use, not merely deleting unwanted material.
Scheduling
Do not delay Build 17 to implement all these uses.
Create requirements and schedule them according to dependencies on agriculture, construction, terrain, roads, and settlement expansion.
Build 17 should preserve and correctly account for recoverable materials.
5. MIN-E-Q2 — RAW STONE AND FINISHED BUILDING BLOCKS
ALREADY APPROVED — DO NOT REOPEN
The owner previously approved separate raw quarry stone and finished building blocks.
The required production chain is:
Quarrying → raw stone → stoneworking → finished building blocks → construction
The conversion must require genuine labor, tools, time, and appropriate facilities.
No free conversion.
The existing STONE-01 implementation work should remain the authoritative implementation track.
Do not create a duplicate requirement or independent implementation.
6. MIN-E-Q3 — TRIAL-PIT SPOIL
RESOLVED BY MIN-D-Q3 — DO NOT REOPEN
Trial pits produce conserved, recoverable excavated material.
Use the MIN-D-Q3 decision as the authoritative resolution.
Do not duplicate implementation.
7. MIN-E-Q4 — CRAFTABLE SHOVELS
OWNER DECISION: APPROVED
Introduce craftable shovels for topsoil and loose-earth excavation.
Retain pickaxes for rock and hard materials.
Required production
A shovel must have a legitimate manufacturing process involving:

* Real component materials.
* Appropriate carpenter-made wooden components.
* Appropriate smith-made metal components.
* Actual crafting labor.
* Required tools and facilities.
* Production time.

Use the existing crafting and equipment architecture wherever possible.
Tool behavior
Shovels are the appropriate excavation tools for topsoil and loose earth.
Pickaxes remain appropriate for hard rock and other applicable hard material.
Both tool categories must have legitimate durability and wear.
Worn or broken tools must require repair or replacement through existing economic processes.
Do not provide free tools or automatic replacements.
Player/NPC parity
Apply equivalent requirements to players and NPCs.
Avoid creating a special exemption for either.
Compatibility
Review existing excavation interactions, work orders, recipes, inventories, and saves.
Do not strand existing saves or introduce an unhandled tool dependency.
8. MIN-E-Q5 — OPEN-PIT ACCESS AND MINING RIGHTS
OWNER DECISION: APPROVED
Preserve open access to suitable common ground for both players and NPCs.
Do not create automatic:

* Manor mining rights.
* Universal royalties.
* Mining permits.
* Mandatory manor authorization.
* Extraction quotas.

Land rights
Existing legitimate property ownership must be respected.
Excavation on land owned or controlled by another party may require the appropriate owner's consent or a negotiated agreement.
Open common ground remains available subject to legitimate physical site restrictions.
Restrictions
Do not revive OD-01 P1.2, which the owner explicitly canceled.
The manor must not automatically acquire ownership of mineral deposits or excavation rights simply because it governs the settlement.
Preserve the existing physical restrictions concerning roads, buildings, access, and other occupied land.
9. MIN-E-Q6 — EXCAVATION SPECIALISTS AND GENERAL LABORERS
OWNER DECISION: APPROVED
Support both specialized excavators and general laborers.
Excavation must not be restricted exclusively to a dedicated occupation.
Specialization
Villagers may develop excavation specialization through genuine:

* Work experience.
* Skill development.
* Employment.
* Repeated practical participation.

Specialists may become more effective as their actual skills improve.
General labor
Appropriately equipped nonspecialists must remain eligible to perform suitable excavation work.
A villager should not be prohibited from digging merely because their job title is not "excavator."
Capability evaluation
Mining capability must reflect real:

* Available workers.
* Relevant skills.
* Appropriate equipment.
* Facilities and physical capabilities.

Do not count job titles as substitutes for actual competence.
Apply the same underlying rules to the player.
Economic behavior
Specialization does not guarantee employment.
Workers must remain free to pursue available opportunities according to their needs and circumstances.
10. MIN-E-Q7 — LARGER AND DEEPER OPEN PITS
OWNER DECISION: APPROVED FOR FUTURE EXPANSION
Preserve the current 5 × 5 open-pit system for Build 17.
Plan future support for:

* Larger excavation footprints.
* Deeper pits.
* Multiple geological strata.
* Spiral ramps.
* Switchback ramps.
* Appropriate terrain representation.
* Updated pathfinding and access.
* Physical material extraction and hauling.

Requirements
Larger pits must require legitimate excavation work, labor, equipment, time, and resources.
Excavated materials must remain conserved.
Deep excavation must not bypass the existing geology or generate unlimited resources.
Ramp and access construction must reflect the actual excavation geometry.
Scheduling
This is not a Build 17 release blocker.
Track it as future work dependent on terrain, world representation, pathfinding, and mining-system expansion.
Do not attempt a major terrain-engine rewrite during Build 17.
11. MIN-C-Q2 — SHARING AND SELLING PROSPECTING INFORMATION
OWNER DECISION: APPROVED
Players and NPCs may voluntarily share prospecting discoveries or negotiate payment for information.
Knowledge requirements
A seller must genuinely possess the information being offered.
A character cannot sell knowledge they have never obtained.
Preserve the existing uncertainty of prospecting findings.
Information may be inaccurate or inconclusive because of legitimate prospecting uncertainty.
Do not guarantee a successful mineral discovery simply because information was purchased.
Negotiation
Buyers may:

* Evaluate an offer.
* Negotiate its price.
* Accept it.
* Reject it.

Sellers may also accept or reject proposed terms.
All payments must be conserved.
Rights
Selling information does not automatically transfer:

* Land ownership.
* Mineral ownership.
* Mining rights.
* Access rights.
* Extraction rights.

These are separate matters requiring their own legitimate ownership or contractual arrangements.
Integration
Implement through the appropriate future information-trading or service-contract framework.
Preserve the existing prospecting and knowledge systems.
Do not delay Build 17.
12. CON02-S-1 — RESTRICTED SERVICE ADVANCES
OWNER DECISION: APPROVED
Allow optional, negotiated buyer-funded advances for specifically identified service expenses.
Requirements
An advance must:

* Be voluntarily agreed upon.
* Identify its intended expense.
* Come from actual available buyer funds.
* Be restricted to its agreed purpose.
* Remain auditable.
* Be reconciled against contract obligations.
* Avoid duplicate reimbursement or payment.

Examples may include legitimate assay fees or other necessary service expenses.
Restrictions
No automatic advances.
No subsidies.
No money creation.
No unrestricted transfer disguised as an expense advance.
No automatic guarantee that the financed service succeeds.
Integration
Coordinate with OD-LE-07 and its restricted-advance framework.
Do not delay Build 17.
13. CON02-S-2 — NEGOTIATED SERVICE COMPENSATION
OWNER DECISION: APPROVED
Service contracts may use different negotiated compensation arrangements.
Permitted structures include:

1. Payment for verified completed work.
2. Payment for verified successful results.
3. Base compensation plus performance bonuses.

Requirements
Both parties must knowingly agree to the compensation structure.
Payment conditions must be objectively verifiable by the simulation.
Contract obligations must be backed by real funds and accounted for.
No contract may promise money that the system silently creates.
Failure
Failed ventures remain possible.
A barren prospecting survey must not magically produce ore to satisfy a results-based agreement.
A worker may accept the risk of results-based compensation, but the system must not force that arrangement.
Implementation
Preserve the existing work-based payment behavior as the working default until negotiated compensation structures are implemented and tested.
Schedule broader compensation options through the contract-system expansion.
Do not delay Build 17.
14. CON02-S-3 — INCOMPLETE WORK AND CONTRACT DISPUTES
OWNER DECISION: APPROVED
Support negotiated contractual protections and a legitimate dispute process.
Contract terms
Agreements may specify:

* Deadlines.
* Objective quality requirements.
* Payment retention.
* Completion criteria.
* Remedies for breach.
* Relevant obligations of both parties.

Dispute process
Disputes may be brought before the appropriate local authority.
The decision must consider:

* The actual agreement.
* Verifiable work records.
* Available evidence.
* Applicable rules and laws.
* Whether either party failed to meet its obligations.

Either party may prevail or lose.
Protections
Earned compensation must be protected according to the agreement and applicable rules.
Funds must remain conserved.
Do not arbitrarily confiscate money or automatically rule in favor of the buyer, seller, player, or manor.
Integration
Coordinate with future political, legal, and judgment systems, including OD-LE-06 where applicable.
Do not introduce an untested judicial system into Build 17.
15. CON02-S-4 — AGRICULTURAL LABOR CONTRACTS
OWNER DECISION: APPROVED
Players and NPCs may negotiate agricultural labor contracts for harvesting and other appropriate farm work.
Contract requirements
Agreements must identify:

* Work to be performed.
* Compensation.
* Deadlines.
* Responsibilities.
* Crop ownership.
* Relevant access and work permissions.

Ownership
Authorized harvesting under a valid contract is not theft.
Harvested crops remain the legitimate owner's property unless ownership is separately and lawfully transferred.
The worker does not acquire ownership merely by collecting the crop.
Simulation
Farmers must be able to evaluate whether hiring help is worthwhile.
Workers must be free to accept or reject available work.
Contracts must respect time, labor availability, equipment, and existing obligations.
Harvest success is not guaranteed.
A farmer may fail to hire enough workers or complete the harvest in time.
Integration
Coordinate with the agricultural, job-market, and service-contract systems.
Do not delay Build 17.
16. CON02-S-5 — INDEPENDENT NPC SERVICE HIRING
OWNER DECISION: APPROVED
NPCs must eventually be capable of independently identifying legitimate service needs and negotiating work across appropriate industries.
Required decision process
An NPC considering a service contract should evaluate:

1. Whether a genuine need exists.
2. Whether performing the work personally is practical.
3. Whether hiring another person would be beneficial.
4. Whether the NPC can afford the proposed expense.
5. Whether qualified providers are available.
6. Whether the proposed price and terms are acceptable.
7. Whether the work can realistically be completed.
8. Whether the agreement conflicts with existing obligations.

The NPC must be free to proceed, negotiate, postpone, or decline.
Applicable industries
This framework should eventually support appropriate services across mining, prospecting, agriculture, construction, hauling, repairs, and other legitimate occupations.
Do not create a separate artificial hiring mechanism for every profession when a common service-contract system can handle the work.
Restrictions
No guaranteed contracts.
No fabricated demand.
No guaranteed worker availability.
No automatic acceptance.
No free materials or equipment.
No created currency.
No teleportation of goods.
No ignoring existing obligations or travel time.
NPC autonomy
NPCs must make decisions based on their own needs, resources, circumstances, and available information.
They must not hire people solely because the simulation needs economic activity.
Integration
The existing service-contract engine can be extended incrementally.
Phase independent NPC service hiring by actual industry needs and supporting systems.
Do not delay Build 17.
17. CON02-S-6 — SEPARATE SERVICE-CONTRACT SIGNING THRESHOLD
OWNER DECISION: APPROVED IN PRINCIPLE
Service contracts will have a formal-signing threshold separate from the existing goods-contract threshold.
Current behavior
The existing system uses a 50-coin threshold for formal face-to-face signing.
Approved direction
Service contracts must support their own independently configurable threshold.
Outstanding parameter
The owner has not yet selected the numerical service-contract threshold.
Do not invent or silently approve a number.
Do not interpret the existing 50-coin threshold as the owner's final choice for services.
Until the numerical threshold is approved and the separate rule is implemented, preserve the existing 50-coin behavior as the working default.
Implementation
Track the threshold as an unresolved numerical parameter, not as an unanswered design-direction question.
The numerical amount must be approved before the new separate service threshold becomes active.
Do not delay Build 17.
18. IMPLEMENTATION PRIORITIES AND BUILD BOUNDARIES
These decisions do not automatically authorize expanding Build 17's release scope.
Build 17 integration
Review and implement the narrow changes that are appropriate and safe for the current build, particularly:

* Player/NPC parity in mining capability.
* Recoverable trial-pit excavation materials.
* Consistency with MIN-E spoil and topsoil inventories.
* Any shovel integration that can be completed without destabilizing excavation or save compatibility.
* Existing mining-rights behavior and tests.
* Correct capability accounting for actual excavators.
* Existing stone-processing work under STONE-01.

If a change creates substantial new dependencies, record and schedule those dependencies instead of rushing an incomplete implementation.
Deferred implementation
Create or update tracked requirements for:

* Farmland soil improvement.
* Road embankments and construction.
* Building-site grading.
* Defensive earthworks.
* Landscaping.
* Larger and deeper pits.
* Advanced ramps and geological strata.
* Negotiated prospecting-information sales.
* Restricted service advances.
* Negotiated compensation structures.
* Contract disputes and remedies.
* Agricultural labor contracting.
* Independent NPC service hiring.
* Separate service-contract signing thresholds.

Use existing requirement IDs and planned workstreams where possible.
Do not duplicate work already tracked under STONE-01, OD-LE-06, OD-LE-07, or other established requirements.
19. REQUIRED ENGINEERING SAFEGUARDS
For every implemented change, preserve:
Determinism
Equivalent initial state, seed, inputs, and actions must produce equivalent outcomes.
Conservation
Currency, inventory, geological deposits, excavated materials, and contract obligations must reconcile.
Save compatibility
Existing saves must continue to load correctly, with safe defaults or explicit migration for new data.
Player/NPC parity
Equivalent actions and circumstances must use equivalent underlying rules.
Physical simulation
Goods, materials, and tools must move through legitimate processes rather than teleporting.
NPC agency
NPCs may refuse, fail, negotiate, change occupations, or abandon opportunities when appropriate.
Performance
Avoid unnecessary daily scans, expensive per-frame work, or systems that undermine established performance targets.
Regression control
Reuse existing test and CI evidence when valid. Run targeted tests for changed systems and the appropriate final integration gates.
Do not rerun expensive suites repeatedly without a meaningful change or reason.
20. REQUIRED COMPLETION REPORT
After recording these decisions, provide a concise but complete report containing:
A. Decision ledger
For each of the 14 newly answered questions, identify:

* Requirement/question ID.
* Owner-approved decision.
* Recorded documentation location.
* Existing implementation status.
* Required implementation changes.
* Build 17 versus future-build assignment.

Also identify MIN-E-Q2 and MIN-E-Q3 as previously resolved duplicates.
B. Build 17 work
List any work that must be completed before Build 17's technical validation.
Explain any implementation you deferred and why.
C. Dependencies
Identify relevant relationships with:

* STONE-01.
* MIN-F underground systems.
* MIN-G simulation validation.
* Expansion 18.
* OD-LE-06.
* OD-LE-07.
* Future construction and agricultural systems.
* Expansion 19 judgment systems, where relevant.

D. Outstanding owner input
The service-contract formal-signing threshold is the one explicitly deferred numerical parameter from this review.
Do not reopen approved design decisions.
E. Validation
Report test outcomes, determinism results, conservation results, save compatibility, and any known remaining risks.
F. Release readiness
Clearly distinguish:

* Decision approval.
* Implementation completion.
* Technical validation.
* Owner release authorization.

Decision approval is not release authorization.
FINAL DIRECTIVE
These 14 owner questions have been answered.
Do not ask them again.
Do not silently substitute existing implementation defaults for the approved decisions.
Do not convert deferred future features into Build 17 blockers without a genuine technical dependency.
Maintain one coherent simulation architecture rather than creating separate special-case systems for every profession.
The goal is not to guarantee a successful village.
The goal is to build a village whose people, economy, resources, relationships, and institutions operate consistently enough that success or failure emerges naturally from their decisions.
A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
