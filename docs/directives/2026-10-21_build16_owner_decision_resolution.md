# Owner directive, 2026-10-21: Build 16 owner decision resolution

Saved verbatim. The owner's answers to the eleven questions of `docs/BUILD_16_STATUS.md` section C (the report of
2026-10-20). Register: OD-25 (this directive) and the entries it names: FARM-07, FARM-01, FARM-02, STALL-01, STALL-05,
FSE-12, FSE-13, FSE-B06, OD-20, EQ-22, OD-17, DVW-A12, DVW-B6.

---

MY MEDIEVAL LIFE — BUILD 16

Owner Decision Resolution and Implementation Directive

October 20, 2026

These are my final decisions on the eleven questions raised in the latest Build 16 status report.

Update the decision register, Build 16 tracking documents, implementation plans, and associated tests accordingly.

These decisions supersede conflicting proposals but do not cancel previously approved requirements unless explicitly stated below.

Do not reopen resolved decisions without identifying a genuine technical contradiction or implementation blocker.

---

1. FARM-07 — Farmland Lease

APPROVED: 2 coins per week.

Family farmland leases cost 2 coins weekly, consistent with the existing land-leasing system.

Requirements:

- Both player and NPC households can lease farmland.
- Payments use the existing lease scheduling and accounting mechanisms.
- Lease revenue goes to the appropriate manor or realm treasury.
- No duplicate lease charges or invented secondary land fees.
- Apply existing rules for ownership, missed payments, expiration, and land access where applicable.
- Do not invent new penalties or eviction mechanics.

A farmland lease grants access to the land. It does not automatically construct a field or supply materials.

Preserve the previously approved requirement that the household must physically develop the land.

---

2. FARM-01 / FARM-02 — Variable Plot Sizes and Construction

APPROVED: Variable plot sizes. Reject the proposed mandatory 5×6 plot.

Players and NPC households must be able to establish farmland of different sizes within the constraints of the existing land system.

Requirements:

- Use the approved green-square placement interface.
- Validate land boundaries, existing leases, terrain, obstructions, and accessibility.
- Require clearing trees and other applicable obstructions.
- Use actual logs and stone to construct fences and gates.
- Calculate required construction materials from the actual plot perimeter and resulting fence and gate geometry.
- Do not charge a fixed amount of materials regardless of plot size.
- Do not invent a new material recipe when an appropriate existing construction recipe is available.
- Require actual construction labor.
- Preserve the ability to plow, plant, tend, and harvest the developed land.

The exact material quantities must come from the game's established construction and resource rules.

If the existing rules lack a necessary fence or gate recipe, identify that gap and propose the smallest consistent addition for approval.

NPC behavior

NPC households should select plot sizes according to their actual needs, resources, finances, available labor, and goals.

Do not require every NPC household to lease or construct the same-sized farm.

Do not create free fences, gates, tools, seeds, or construction materials for NPCs.

Lease pricing

The approved farmland lease rate remains 2 coins weekly.

Do not introduce a new plot-size pricing formula without owner approval.

If existing land constraints or lease rules conflict with variable plot sizes, document the conflict rather than silently changing the approved price.

---

3. STALL-01 / STALL-05 — Market Stall Economics

APPROVED: 5% commission on actual completed sales.

This replaces the proposed flat pitch rent for stalls operating under the approved OD-24 model.

Before implementation, audit the existing stall construction recipes, land arrangements, merchant stalls, transaction settlement, and accounting rules.

Required stall behavior

1. A player or NPC obtains an appropriate stall location through the approved land and placement system.
2. The owner clears and prepares the site.
3. The stall is constructed using actual materials and labor.
4. The owner places real inventory into the stall.
5. The owner activates OPEN STALL.
6. The stall can operate while the owner is elsewhere.
7. Customers purchase goods using actual available money.
8. When saleable inventory is exhausted, the stall closes automatically.
9. The owner may also use CLOSE STALL.
10. Closing the session settles the realm's 5% commission on completed sales.
11. Unsold inventory remains the owner's property.

Example:

- Completed sales: 100 coins.
- Realm commission: 5 coins.
- Owner receives: 95 coins.

The commission must never be charged against unsold inventory, asking prices, or hypothetical sales.

Construction audit

Do not automatically adopt the proposed recipe of six planks and one iron bar.

Inspect existing construction definitions and use established recipes where appropriate.

Report missing requirements or genuine recipe conflicts before inventing replacements.

Settlement audit

Verify:

- When sales revenue is recorded.
- How the 5% commission is calculated.
- How fractional commission amounts are handled.
- When funds move to the treasury.
- How sessions are closed.
- How interrupted sessions are recovered.
- How inventory and coin conservation are enforced.

I have not approved a rounding rule.

Use an existing authoritative monetary rounding convention if one exists and is applicable. Otherwise, present the options and request approval before introducing a new rule.

Do not create duplicate charges or permit transactions to be settled twice.

Existing merchant stalls

Audit existing free stalls and the previous five-coin daily pitch-rent system.

Identify which locations are covered by OD-24 and which represent distinct preexisting arrangements.

Do not silently convert unrelated merchant arrangements without checking their intended role.

---

4. FSE-12 — Shared Manor Farming Model

APPROVED: Move the manor's six fields to the shared per-cell farming model behind a test switch.

The player, NPC households, and manor farming operations should ultimately use the same underlying agricultural mechanics.

Requirements:

- Implement the shared farming model.
- Preserve existing resource and labor accounting.
- Account for actual seeds and planting inputs.
- Maintain deterministic behavior.
- Keep the new model behind a controlled testing switch initially.
- Run comparative simulations using the old and new models.
- Measure crop yields, labor, seed consumption, food supply, and economic effects.
- Do not activate the new model universally until its results have been reviewed.

The switch is a testing and migration mechanism, not authorization to maintain permanently inconsistent farming rules.

---

5. FSE-13 — Seasonal Village Farming

DECISION: Comparison testing first, then owner review.

Implement and test the seasonal farming model in isolation or behind an appropriate test switch.

Do not enable it globally merely because automated tests pass.

The comparison report must evaluate:

- Planting opportunities by season.
- Growth and harvest timing.
- Crop yields.
- Seed consumption.
- Household food availability.
- Manor production.
- NPC farming decisions.
- Starvation and food-security effects.
- Economic consequences.
- Determinism.

Preserve the established calendar:

One calendar year equals eight game days, with four seasons of two game days each.

Do not accidentally use 365 game days as one calendar year.

After comparison testing, present the results and request my authorization before activating seasonal village farming across the simulation.

---

6. FSE-B06 — Bandit Camp Cooking

APPROVED: Retain the current deadwood cooking behavior temporarily.

Bandits may continue roasting meat using the existing deadwood campfire mechanism while the larger bandit-factions system remains unfinished.

This is an intentional interim exception, not permission to create unlimited food.

Preserve the existing requirement that bandits eat actual food obtained through legitimate simulation activities such as buying, stealing, or poaching.

A band without food must experience hunger.

Record the deadwood behavior as a dependency for the future bandit-factions expansion, where wood gathering and supply logistics can be addressed.

Do not expand Build 16 into the complete bandit-factions system.

---

7. OD-20 — Pickpocket Witness Reporting

APPROVED: Use the witnessed-crime reporting system.

A caught pickpocket should generate a witness report consistent with the existing crime and judgment design.

Requirements:

- Crime awareness must originate from legitimate witnesses.
- Guards must not gain omniscient knowledge of unwitnessed crimes.
- Reports must follow the existing communication and information-sharing rules.
- Do not automatically turn every pickpocket incident into an audible alarm.
- Preserve consistency with previously approved witness-based crime behavior.

Do not use this change to prematurely implement the entire Build 19 NPC Judgment expansion.

---

8. EQ-22 — Caravan Purchasing Priorities

APPROVED: Allocate purchasing according to actual demand and need.

Remove unconditional priority that causes smiths to consume most of the caravan's purchasing funds simply because of their position in the buying order.

Caravan purchasing decisions should account for:

- Actual inventory needs.
- Production requirements.
- Available caravan funds.
- Available merchant stock.
- Prices and economic conditions.
- Legitimate competing demand from other businesses.

The caravan must operate within the same resource and currency conservation rules as the rest of the economy.

Do not guarantee that every business receives a purchase.

Do not invent an arbitrary equal distribution of funds.

Purchases should emerge from the businesses' actual needs and the caravan's available resources.

Use deterministic decision-making where required by the simulation.

---

9. OD-17 — Game Designer Specification

REMAINS BLOCKED. NO NEW APPROVAL GIVEN.

Do not implement Claude's recommended answers to the unresolved hero, camera/view, or Steam Deck labeling questions merely because they appear in the decision register.

Retrieve and present the exact existing OD-17 register entry, including:

- Original questions.
- Available options.
- Existing recommendations.
- Relevant design dependencies.
- Consequences of each choice.

Preserve the original wording and context.

Wait for my explicit decisions.

Do not invent missing options or treat silence as approval.

Continue independent work that does not depend on OD-17.

---

10. DVW-A12 — UI Rules Refactor

APPROVED DEFERRAL: Move to Build 17.

Move the planned refactor of gameplay rules out of UI code and into core systems to the beginning of Build 17.

Requirements:

- Preserve the task and its acceptance criteria.
- Record the dependency and reason for deferral.
- Do not mark the work complete.
- Do not remove existing functionality.
- Do not use the deferral as permission to introduce new UI-dependent gameplay rules.

If an actual Build 16 defect requires a narrowly scoped correction, address the defect without unnecessarily performing the full deferred refactor.

---

11. DVW-B6 — Overworld Wildlife Migration

APPROVED DEFERRAL: Move to Build 18.

Move wildlife wandering into the village from the overworld to Build 18.

Preserve the design and associated acceptance criteria.

Do not implement the full migration system during Build 16.

Continue to fix existing wildlife defects that affect approved Build 16 functionality.

Do not confuse deferral of the new migration feature with permission to leave existing regressions unresolved.

---

12. Preserve Existing Build 16 Requirements

These decisions do not cancel the previously approved systems.

Build 16 continues to include the approved scope for:

- Household food security and shared family pantries.
- Starvation investigations and food accounting.
- Player/NPC mechanical parity.
- Family farmland leasing and construction.
- Crop seeds, planting, harvesting, and propagation.
- Fruit trees, berry bushes, and flowers.
- Village seed and planting-material merchants.
- Market stalls and completed-sale commissions.
- Skilled-trade sales counters.
- Armorer availability and functionality.
- Shopkeeper navigation and customer interactions.
- Trade-specific buying and selling.
- Construction materials and labor.
- Actual inventory and coin conservation.
- Deterministic simulation.
- The existing time and calendar model.
- Approved release blockers and regression fixes.

Armorer and sales counters

The armorer remains a confirmed open release blocker.

There is currently no functional armorer job, the armoury counter is decorative, and the smith cannot reliably serve customers while occupied.

Implement the previously approved counter interaction:

Approach counter → interaction prompt → press A → available shopkeeper comes to counter → trade.

The shopkeeper must use normal navigation and remain subject to ordinary NPC needs and schedules.

If unavailable, communicate that to the player.

The system must support appropriate skilled businesses without requiring a completely separate interaction implementation for each profession.

Farming and planting

Variable farmland must support real preparation, construction, plowing, seed planting, tending, and harvesting.

Include the approved propagation system for crops, fruit trees, berry bushes, and flowers.

Harvesting should have appropriate chances to recover viable seeds or propagation materials.

Perennial plants should survive harvesting when appropriate.

Both player and NPC households must use the same underlying mechanics.

Expansion boundaries

Keep the separately planned Living Economy expansion and Build 19 NPC Judgment expansion in their existing milestones.

Do not silently move their full scope into Build 16.

Conversely, do not move approved Build 16 features into later milestones without my permission.

---

13. Verification and Acceptance

Continue the existing four-seed, 365-game-day acceptance simulations on the latest verified code.

Report:

- Starvation deaths by seed and cause.
- Firewood availability and actual consequences.
- Script errors.
- Inventory conservation.
- Coin conservation.
- Determinism.
- Test-suite results.
- Regressions against prior baselines.

Do not claim the recent starvation fixes have eliminated deaths until the latest runs confirm their effects.

A zero-starvation outcome is not an automatic acceptance requirement. The objective is mechanically correct behavior and explainable consequences, not artificially guaranteed survival.

Preserve the verified test baseline.

Any changes to test expectations must be justified by approved rule changes, not merely adjusted to make failing tests pass.

---

14. Development Execution and Agent Limits

Continue approved development autonomously.

Use the previously authorized controlled parallel-development arrangement:

- One primary coordinating agent.
- Up to two additional workers when genuinely justified.
- No nested agents.
- No duplicated full-repository investigations.
- No unnecessary repeated test-suite runs.
- Expensive long-running simulations coordinated by the primary agent.
- Narrow, independent assignments with clear acceptance criteria.

Given the reported worker usage, prefer one additional worker until parallel efficiency is demonstrated.

Monitor actual token and credit consumption where available.

Do not invent savings or cost estimates.

Use RTK where available and appropriate, but do not sacrifice necessary diagnostic information merely to reduce output.

---

15. Required Register and Status Updates

Update the authoritative decision register and "docs/BUILD_16_STATUS.md".

For each decision:

1. Record the approved owner choice.
2. Link the affected work-item IDs.
3. Update dependencies and acceptance criteria.
4. Record any approved deferral.
5. Preserve unresolved decisions as blocked.
6. Identify whether implementation is complete, in progress, awaiting testing, or not started.

Reconcile the latest staging commit hashes and report the actual verified HEAD.

Do not mark an owner decision as implemented merely because it has been approved.

Final response to owner

Provide a concise report containing:

- Confirmation that all eleven decisions were recorded.
- Which decisions are ready for implementation.
- Which items remain blocked.
- Which two tasks were deferred.
- Any genuine conflicts discovered.
- The next three development priorities.
- Current Build 16 completion status.
- Latest verified commit and test status.

Continue implementation in dependency order.

Commit and push verified work to the approved staging branch.

Do not merge, publish, or create a public release without explicit owner authorization.

Final owner intent

Build 16 is an expansion milestone, not a small patch.

The purpose is to build interconnected systems that operate under consistent economic, physical, and simulation rules.

Use the actual world, actual materials, actual labor, actual money, and genuine NPC decisions.

Do not artificially force favorable outcomes.

Do not silently expand future milestones or shrink the approved Build 16 scope.

Implement the decisions above, preserve the existing design, verify the results, and keep development moving.
