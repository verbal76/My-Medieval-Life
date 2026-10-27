MY MEDIEVAL LIFE — OWNER DEVELOPMENT DIRECTIVE

COMPLETE EXPANSION 20 — LIVING ECONOMY

FINISH EXISTING WORK BEFORE OPENING ANOTHER EXPANSION

Claude, I am selecting OPTION 1.

FINISH EXPANSION 20 BEFORE BEGINNING EXPANSION 21.

We have already invested substantial development effort into the Living Economy, and I want that system completed, integrated, tested, and ready for gameplay before opening another major development workstream.

Expansion 21 remains on the roadmap with its previously approved scope, but its implementation must wait.

This is a development-priority decision, not a cancellation of Expansion 21.

---

1. CURRENT PROJECT BASELINE

Build 23 has been produced as a private playtest checkpoint.

It is NOT the completed Expansion 20 release.

The latest report states:

- 83 approved Expansion 20 items.
- 69 implemented and merged.
- Remaining Living Economy stages LE-02 through LE-07.
- Permanent employment not yet implemented.
- Gameplay polish carryovers outstanding.
- Judgment calibration and owner review outstanding.
- Flight-recorder diagnostics in progress.
- Unowned shop tills discovered in the LE-01 foundation.

Verify this status against the existing project registers and repository.

Do not reopen completed work unless a verified dependency or defect requires it.

Preserve Build 23 as the existing playtest checkpoint.

Do not make the release public without my explicit authorization.

---

2. IMMEDIATE PRIORITY — COMPLETE THE FOUNDATION

Before proceeding into additional Living Economy functionality:

A. Complete REC-DIAG

Finish the simulation flight-recorder diagnostic system.

It must provide useful, reproducible evidence when economic or simulation behavior becomes abnormal.

Ensure it can identify relevant events involving:

- NPC decision-making.
- Household resources.
- Food availability.
- Production.
- Employment.
- Trade.
- Ownership.
- Currency transfers.
- Settlement conditions.
- Migration.
- Unusual deaths.
- Economic instability.

Preserve existing diagnostic capabilities.

Avoid excessive logging or unnecessary performance overhead.

B. Correct shop-till ownership

The LE-01 foundation contains shop tills without recorded owners.

This needs correction before LE-04 finance work.

Every business holding money must have a traceable legal/economic ownership relationship consistent with the approved ownership model.

Investigate the actual cause.

Correct the underlying ownership initialization or persistence problem.

Ensure the correction covers:

- Existing businesses.
- Newly created businesses.
- Ownership transfers.
- Inheritance where applicable.
- Save/load.
- Business closure.
- Economic transactions.

Money must not become ownerless, duplicated, or destroyed because of missing ownership records.

Create focused regression tests.

Do not invent new business ownership rules.

Use the previously approved Living Economy policies.

---

3. COMPLETE LE-02 THROUGH LE-05

Continue development in the existing approved order.

LE-02 — HAGGLING AND PRICE NEGOTIATION

Implement the approved negotiation systems.

The economy must support NPCs making genuine decisions based on their needs, resources, relationships, and circumstances.

Preserve our established principle that NPCs have individual motivations rather than automatically accepting offers.

Use the approved negotiated quantity-based procurement contracts.

For example, a buyer may offer a price per unit for a specified quantity of a tradable product.

This mechanism should work across applicable tradable products, rather than being restricted to mining or agriculture.

Do not invent additional financial policies.

LE-03 — PRODUCTION, CAREERS AND HOUSEHOLD BUDGETS

Complete the approved production and household economy systems.

Preserve individual NPC autonomy.

Households must evaluate their actual needs and available resources.

Businesses must operate using legitimate ownership and financial relationships.

Production should respond to realistic economic conditions rather than arbitrary resource creation.

Keep any career-choice behavior behind its existing disabled gate until its authorization conditions are satisfied.

LE-04 — FINANCE, MERCHANTS AND MANOR INTERACTIONS

Complete the approved systems using the corrected LE-01 ownership foundation.

Maintain financial integrity.

Currency and inventory movements must remain traceable.

Preserve the existing manor powers unless an approved decision explicitly changes them.

Do not introduce money lending, interest, debt collection, or other unresolved policies without owner approval.

LE-05 — CONSTRUCTION, ECOLOGY, MINING, BANDITS AND SETTLEMENT CONNECTIONS

Complete the approved integration work.

Preserve the existing mining sustainability mechanics.

Surface deposits, open-pit deposits, and cave deposits use the same recognized ore-bearing objects and established depletion rules.

Independent miners may extract for personal needs or sell to willing buyers at negotiated prices.

Use the existing NPC interaction framework for applicable labor and procurement contracts.

Do not create separate mining-only economic rules.

Ensure resource movement and trade respect the approved settlement economy policies.

Do not silently implement unresolved off-map settlement decisions.

---

4. COMPLETE THE CARRYOVER WORK

Expansion 20 must also address its approved outstanding carryovers.

EMP-PERM-01

Implement permanent employment of villagers by the player according to its approved requirements.

Integrate it with the existing employment, contract, production, and NPC relationship systems.

GP-POLISH

Complete the authorized gameplay polish batch, including:

- Anvil interactions.
- Lockpicking.
- Android joystick improvements.

Do not expand this into an unrelated visual redesign.

SJD-G AND SJD-H

Complete the authorized judgment-system calibration work and supporting evidence.

Maintain the existing feature gates.

SJD-H requires my review before activation.

Do not enable judgment behavior without approval.

Do not activate aspirations, career choice, witness-reporting decisions, or the Living Economy model merely because related code has been implemented.

Previously established owner approval requirements remain binding.

---

5. RESOLVE OPEN DECISIONS PROPERLY

The current update identifies eight decisions requiring my attention:

- MP-INTERACT-Q1.
- MP-INTERACT-Q2.
- REG-X20-D1 through D4.
- ARMOR-CATALOG-D1.
- ID-D3.

Review the authoritative decision register for any additional unresolved Expansion 20 questions.

Distinguish between:

1. Decisions already answered.
2. Decisions awaiting final owner approval.
3. Questions that genuinely block current implementation.
4. Questions that affect only later stages.

Do not repeatedly ask questions that have already been answered.

Do not silently invent policy.

Continue independent approved work while decisions remain open.

When owner input is necessary, present the outstanding questions together, with:

- Exact decision ID.
- The issue.
- Available options.
- Your recommendation.
- Consequence of each option.
- What implementation is blocked.

Preserve existing decisions exactly.

---

6. BUILD 23 PLAYTEST REQUIREMENTS

Build 23 remains a private draft.

Do not make it public.

The following real-device checks remain outstanding:

- Android installation over Build 22.
- Existing save preservation.
- Windows functionality.
- Controller functionality.
- Multiplayer between two physical devices.

Prepare a concise checklist and capture whatever automated evidence is available.

Do not claim real-device testing has passed without actual evidence.

Do not block independent LE-02 through LE-05 development while waiting for my physical playtests.

Any issues I report from Build 23 should be tracked and assessed against the appropriate development stage.

---

7. LE-06 — ECONOMIC SIMULATION AND PERFORMANCE

Once the required systems are integrated, execute the approved long-duration and multi-seed simulations.

Use GitHub Actions wherever practical.

Preserve deterministic behavior and the existing reporting infrastructure.

Monitor:

- Household survival.
- Food production and consumption.
- Economic equilibrium.
- Employment.
- Wages and contractual obligations.
- Trade.
- Business profitability.
- Currency and inventory conservation.
- Resource depletion.
- Settlement sustainability.
- NPC behavior.
- Performance.
- Memory consumption.
- Save/load consistency.

Investigate systemic defects rather than tuning isolated seeds.

Use new seeds for statistical discovery while retaining historical problem seeds for regression tests.

Avoid redundant campaigns.

Do not manipulate simulation assumptions merely to improve the reported numbers.

---

8. LE-07 — RELEASE READINESS

Complete the required release-readiness work after implementation and simulation validation.

Ensure:

- Approved functionality is implemented.
- Relevant regression tests pass.
- Economic integrity is demonstrated.
- Performance remains acceptable.
- Saves remain compatible.
- Required feature gates remain respected.
- Outstanding owner decisions are recorded.
- Release notes accurately describe the completed work.

Do not publish or promote a release without the authorization required by the existing project instructions.

Do not confuse a completed build with an approved public release.

---

9. DEVELOPMENT EFFICIENCY

We need to control Claude usage.

Use the existing approved specifications, decision registers, and prior test evidence.

Do not commission another broad investigation of systems that have already been audited.

Do not launch unnecessary parallel Opus agents.

Do not duplicate test campaigns.

Use focused testing during implementation.

Reserve long simulation campaigns for the appropriate validation stage.

Make coherent commits.

Preserve context-recovery documentation before compaction.

Avoid excessive administrative updates that interrupt productive engineering work.

Use the existing project-management structure to track completed and remaining work.

The objective is to finish Expansion 20 efficiently, not create additional planning overhead.

---

10. EXPANSION 21 RESTRICTION

Expansion 21 remains the next major expansion.

Its previously approved initial scope is preserved:

- Civic and political audit.
- Civic records.
- Mapping existing owner decisions.
- Political behavior disabled until authorized.

However, do not start its implementation now.

Do not assign a new agent to Expansion 21.

Do not begin new political gameplay systems.

Do not merge unrelated political functionality into Expansion 20.

Preserve the existing mayoral-term ruling and all other settled decisions.

Once Expansion 20 reaches its approved completion point, report readiness to proceed with Expansion 21.

---

11. REPORTING

Maintain one authoritative Expansion 20 progress register.

Track:

- Approved items completed.
- Items remaining.
- Current development stage.
- Relevant commits.
- Tests performed.
- Confirmed defects.
- Outstanding owner decisions.
- Release blockers.

Provide concise updates at meaningful milestones.

Avoid sending dozens of individual progress messages.

When Expansion 20 implementation and validation are complete, produce one consolidated owner report covering:

1. All 83 approved items and their dispositions.
2. LE-01 ownership corrections.
3. LE-02 through LE-05 implementation.
4. Permanent employment.
5. Gameplay polish.
6. Judgment calibration.
7. Simulation diagnostics.
8. Economic and performance results.
9. Build 23 playtest findings.
10. Remaining owner decisions.
11. Release readiness.
12. Expansion 21 handoff readiness.

Do not count unfinished, untested, or disabled functionality as fully released.

---

FINAL OWNER DIRECTION

FINISH EXPANSION 20 FIRST.

Complete the flight-recorder diagnostics.

Correct the unowned shop tills.

Continue the approved Living Economy implementation.

Complete the authorized carryovers.

Keep unresolved features disabled.

Run the required simulations and performance validation.

Preserve Build 23 as a private playtest checkpoint.

Do not start Expansion 21 in parallel.

Do not reopen settled design decisions.

Do not spend excessive resources repeating completed work.

I want My Medieval Life's Living Economy completed as an integrated, functioning system before we move to Village Politics.

PROCEED WITH THE APPROVED EXPANSION 20 WORK.
