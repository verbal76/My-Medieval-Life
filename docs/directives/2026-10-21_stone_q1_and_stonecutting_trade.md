# Owner directive, 2026-10-21: STONE-Q Part 1 and future stonecutting trade (verbatim)

OWNER DIRECTIVE — STONE-Q PART 1 AND FUTURE STONECUTTING TRADE

1. Record the owner's STONE-Q Part 1 decision

Approved: Option C — materials must match the actual construction or repair being performed.

Use the following distinctions:

- Raw stone: rough construction, rubble filling, road maintenance, minor repairs, and ordinary ovens, stoves, and forge hearths where dressed masonry is unnecessary.
- Finished building blocks: structural masonry, substantial stone construction, and major masonry reconstruction.
- Mixed materials: construction or repairs that genuinely require both rough stone and finished masonry must consume the appropriate quantities of each.

The purpose is physical and economic realism, not artificially increasing demand for finished blocks.

Do not force every repair or fitting to consume finished blocks merely to create a market for them.

All material consumption, recovery, transport, production, and inventory changes must obey the existing conservation and determinism requirements.

Build 17 scope limitation

Do not turn this decision into a major redesign of the existing repair system.

Where Build 17 already distinguishes construction or repair types, apply the approved material distinction if it can be done safely within the existing implementation.

Where the existing system cannot distinguish ordinary maintenance from major structural reconstruction, retain the current functioning behavior and record the more detailed distinction for future implementation.

Do not introduce unnecessary save-format changes, conversion exploits, or new release blockers.

Any material returned when dismantling an existing fitting must reflect what was actually consumed. Do not allow old saves to convert raw stone into finished blocks for free.

2. Approve stonecutting as a general skill and activity

Stonecutting is not exclusively a profession.

A player or NPC may dress raw stone into finished building blocks for personal use, including constructing or repairing their own house.

This must operate under the same general rules for players and NPCs.

The ability to dress stone depends on actual capability:

- Appropriate tools and access to a suitable workspace.
- Required raw materials.
- Sufficient skill or ability under the existing capability system.
- Actual work time and tool wear.
- Conservation of materials and resulting products.

An NPC must not be required to hold the formal occupation of stonecutter merely to make blocks for personal use.

Likewise, having the title of stonecutter must not bypass material, skill, equipment, or labor requirements.

Reuse existing STONE-01

Build 17 already reportedly includes a stone-dressing process using a workbench, tools, labor, and time.

Verify what is actually implemented.

Reuse and extend the existing process. Do not create a duplicate stoneworking system.

If personal-use stone dressing is already possible under the existing mechanics, preserve it.

If the existing mechanics need future improvements, record those requirements without unnecessarily expanding Build 17.

3. Approve professional stonecutting as a future career

The owner also approves stonecutting as a legitimate independent profession and business, comparable to blacksmithing or carpentry.

A professional stonecutter may:

1. Acquire raw stone through mining, quarrying, or voluntary purchases.
2. Dress raw stone into finished masonry blocks using the same physical production rules as everyone else.
3. Maintain a workshop or suitable business premises.
4. Hold actual inventory of raw stone, tools, and finished products.
5. Sell finished blocks to private individuals, builders, other businesses, and the manor.
6. Accept negotiated orders for specific quantities of finished products.
7. Make production and purchasing decisions based on genuine demand, available resources, prices, skill, and economic circumstances.
8. Hire assistance or obtain services through the existing or approved general labor and procurement systems, where supported.

Professional stonecutters must participate in the ordinary village economy.

They do not receive free materials, guaranteed customers, artificial sales, privileged access to deposits, or automatic profits.

A stonecutter's business is allowed to succeed, struggle, or fail according to actual economic conditions.

4. Assign professional stonecutting to Expansion 18

The full professional stonecutter career and business implementation is approved for Expansion 18, not Build 17.

Expansion 18 is the preferred owner of this work because it includes settlement capability, production, economic activity, trade, and regional commerce.

Expansion 19 must not independently implement a second stonecutting profession. Its social judgment and relationship systems may later influence stonecutters' ordinary economic decisions through shared NPC decision logic.

Record the new requirement in the authoritative requirements register with an appropriate unique ID.

Mark it:

- Owner-approved.
- Assigned to Expansion 18.
- Not implemented unless verified otherwise.
- Not a Build 17 release blocker.

Include its dependencies on STONE-01, the capability evaluator, ordinary market transactions, and general procurement contracts.

The Expansion 18 worker may assess integration requirements during its existing work, but do not interrupt its current simulations or courier work merely to begin this feature.

Schedule implementation according to actual dependencies and available development capacity.

5. Avoid duplicating the player and NPC systems

Personal stonecutting and commercial stonecutting must use the same underlying production mechanics.

The difference is economic behavior and scale, not separate recipes or physical rules.

A homeowner producing six blocks for a repair and a professional producing sixty blocks for sale should use the same underlying material conversion, tool requirements, and conservation rules, subject to actual skill and production capacity.

The professional business adds inventory management, buying, selling, customer orders, and economic decision-making.

Do not invent a fixed output ratio, mandatory wage, universal price, or production speed without grounding it in existing systems or obtaining an owner decision where needed.

6. Documentation and continuity

Record this directive in:

- The requirements register.
- The owner decision log.
- The appropriate STONE-01 design documentation.
- The Expansion 18 planning and dependency documentation.

Follow the permanent WIKI-01 rule.

The developer reference must document the approved design and implementation status.

The player-facing wiki must describe only mechanics that actually exist and have been verified. Future professional stonecutting belongs in the existing planned-features area until implemented.

Ensure the decision survives conversation compaction and future session changes.

7. Testing and release discipline

Do not run a new comprehensive test campaign merely to record this decision.

When implementation occurs, use focused tests for production, material conservation, tool wear, NPC capability, inventory transfers, and economic behavior, reusing applicable existing CI evidence.

This directive does not authorize a Build 17 release or create additional Build 17 release gates.

The governing principle remains:

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

8. Report back

Confirm:

1. Where STONE-Q Part 1 was recorded.
2. The requirement ID assigned to the future professional stonecutting career.
3. Whether personal-use stone dressing already works in STONE-01.
4. Whether the professional career is correctly assigned to Expansion 18 and excluded from Build 17 blockers.
5. Whether any additional owner decision is genuinely required.

Then present STONE-Q Part 2, with its original question, available options, gameplay consequences, and recommendation.

Wait for the owner's answer before proceeding with that question.

Do not stop or restart the existing workers.
