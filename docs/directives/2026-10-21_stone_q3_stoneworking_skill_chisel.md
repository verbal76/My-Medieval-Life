# Owner directive, 2026-10-21: STONE-Q Part 3 (verbatim)

OWNER DIRECTIVE — STONE-Q PART 3

Dedicated Stoneworking Skill and Iron Chisel

Expansion 18 Approval — Build 17 Scope Protected

OWNER DECISION: 1B + 2B APPROVED

This resolves the third and final STONE-Q question.

The owner approves:

- 1B: A dedicated Stoneworking skill within the existing character skill system.
- 2B: Stone dressing requires both a mallet and an iron chisel.
- Implementation assignment: Expansion 18.
- Build 17: No changes required or authorized by this decision.

Record this decision in the authoritative requirements register, owner decision log, saved directives, stoneworking design documentation, and Expansion 18 roadmap.

Do not reopen STONE-Q Parts 1 or 2.

1. Dedicated Stoneworking skill

Introduce Stoneworking as a distinct skill using the existing player and NPC skill architecture.

It must behave consistently with existing skills such as Mining, Smithing, and Cooking.

Stoneworking proficiency is gained through actual stoneworking activity under the game's normal skill-progression rules.

A character's general Crafting proficiency must not automatically make them an expert stonecutter.

Stoneworking must govern relevant stone-dressing capability and, under the approved STONE-Q Part 2 design, material efficiency.

The same skill rules apply to:

- Players dressing stone for their own construction.
- NPCs dressing stone for their own needs.
- General workers performing stoneworking.
- Professional stonecutters operating businesses.
- Hired workers performing negotiated stoneworking services.

A formal occupation is not required to develop or use the skill.

Holding the occupation of stonecutter does not grant free skill levels or bypass actual production requirements.

Reuse the existing skill system. Do not create a separate stonecutting progression framework.

2. Stoneworking tools

Stone dressing will require both:

1. A mallet.
2. An iron chisel.

The chisel is a real, physically conserved inventory item.

Blacksmiths manufacture chisels using the existing smithing and production systems.

Chisel production must require appropriate real inputs, tools, labor, and production time.

Chisels must be obtainable through ordinary market transactions, inventory transfers, and supported procurement arrangements.

Do not give stonecutters free chisels or guarantee access to them.

Chisels experience wear through actual use and eventually require replacement according to an approved durability model.

Do not invent a permanent chisel durability value, wear rate, production recipe quantity, or market price without first checking existing conventions and obtaining owner approval where a new balancing decision is needed.

If a character lacks a usable chisel or mallet, the stone-dressing operation must respect the normal equipment and capability rules.

Do not bypass those rules because the character is a professional stonecutter.

3. Integrate with STONE-Q Part 2

The owner previously approved skill-based stone-dressing efficiency under STONE-04.

That decision remains in force.

- Beginners generate more waste.
- Experienced stoneworkers recover more usable building material.
- Unused stone becomes physically conserved chips, spoil, or an appropriate existing waste product.
- Production must never create or destroy unaccounted material.
- Waste recovery must not permit unlimited recycling or material duplication.

The Stoneworking skill, rather than general Crafting, will govern this efficiency.

The owner has not approved the skill-to-efficiency table or conversion ratios.

Prepare a proposed model during Expansion 18 design and present it for approval before locking in the values.

Include its effects on resource depletion, construction affordability, stoneworker profitability, and settlement viability.

4. Skill initialization and save compatibility

Adding Stoneworking must not corrupt existing saves or create inconsistent NPC/player data.

Use the project's existing save migration and skill initialization conventions.

However, the owner has not decided whether existing characters should:

- Begin at the normal minimum Stoneworking level.
- Receive partial credit based on existing Crafting proficiency.
- Receive credit based on actual recorded stoneworking history, if such history exists.
- Use another justified migration method.

Do not choose a permanent starting-level or migration-credit policy without presenting the options and obtaining owner approval.

Do not fabricate historical stoneworking experience that the game never tracked.

Update relevant player and NPC skill displays when the feature is implemented.

Preserve deterministic skill progression.

5. Professional stonecutter integration

This decision extends the previously approved Expansion 18 requirement X18-STONECUT.

The professional stonecutter must use the same Stoneworking skill and production mechanics as everyone else.

A professional business adds economic behavior, not privileged production rules.

Professional stonecutters may purchase raw stone, acquire tools, produce blocks, sell inventory, and accept negotiated work under ordinary economic systems.

NPC homeowners must also be able to perform personal-use stone dressing when capable, as approved under STONE-02.

Do not create separate recipes or different physical rules for homeowners, hired workers, and professional businesses.

The career must remain economically autonomous and subject to actual market conditions.

6. Build 17 is explicitly unaffected

Build 17 retains:

- The existing general Crafting skill for stone dressing.
- The existing mallet requirement.
- The current recipe of two raw stone producing two building blocks.
- Existing save behavior.
- Existing tests and release criteria.

Do not backport the Stoneworking skill, iron chisel, skill-based waste, or professional stonecutter career into Build 17.

None of these deferred features becomes a Build 17 release blocker.

Do not interrupt active Build 17 workers to implement Expansion 18 stoneworking changes.

7. Requirements and documentation

Associate this decision with:

- STONE-Q3 — Owner decision, answered.
- STONE-04 — Skill-based stone-dressing efficiency.
- X18-STONECUT — Professional stonecutter trade.
- STONE-02 — NPC personal-use stone dressing.
- STONE-03 — Structural repair and mixed-material differentiation.

Create appropriately scoped new implementation requirement IDs for the dedicated Stoneworking skill and chisel if they are not already represented in the register.

Do not duplicate existing requirements.

Update the system interaction manifest and Expansion 18 dependency plan as appropriate.

Follow WIKI-01:

- Developer documentation records the approved future mechanics and their current implementation status.
- Player-facing documentation continues describing the actual Build 17 Crafting-and-mallet recipe.
- Stoneworking skill, chisels, and skill-based material loss remain identified as planned until implemented and verified.

Do not claim the features are playable before they exist.

8. Testing and development discipline

When Expansion 18 implements this feature, validate:

- Player/NPC skill parity.
- Skill progression and efficiency.
- Material and inventory conservation.
- Chisel production and wear.
- Missing-tool behavior.
- Save migration and backward compatibility.
- NPC production decisions.
- Economic viability and deterministic simulation.

Use focused tests and reuse relevant passing CI evidence.

Do not run a full test campaign merely to record this decision.

The Expansion 18 worker may incorporate this into its planning and dependency analysis without interrupting its currently authorized simulation and courier work.

9. Outstanding owner approvals

The following values and policies remain deliberately unresolved:

1. Starting Stoneworking levels and save migration credit.
2. Skill-to-material-efficiency ratios and thresholds.
3. Chisel durability and wear rates.
4. Chisel production quantities and material recipe, where existing conventions do not already determine them.

Bring these questions to the owner during the relevant Expansion 18 design phase.

Do not turn them into immediate Build 17 questions.

10. Required confirmation

Report:

1. Where STONE-Q3 was recorded.
2. The requirement IDs assigned to the Stoneworking skill and chisel.
3. Confirmation that STONE-Q Parts 1, 2, and 3 are all answered.
4. Confirmation that Build 17 remains unaffected.
5. Any genuine conflicts with existing Expansion 18 requirements.

Then continue authorized development.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
