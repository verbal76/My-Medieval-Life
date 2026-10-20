# Owner directive, 2026-10-20: OD-14 housing expansion and future procedural village generation

Saved verbatim from the owner's message. Register: OD-14 (answered), HOUSE-09, HOUSE-10, HOUSE-11 (Phase 1, Build 15); PVG-01..07 (Phase 2, future procedural village generation).

---

MY MEDIEVAL LIFE — OD-14 HOUSING EXPANSION AND FUTURE PROCEDURAL VILLAGE GENERATION

Claude,

I have made my decision regarding OD-14 and want to establish a permanent design direction for procedural village generation.

There are two phases to this directive. The first concerns the existing village and Build 15 stabilization. The second establishes requirements for future procedurally generated villages.

Do not confuse the two phases or begin a major world-generation rewrite during Build 15.

PHASE 1 — OD-14: EXISTING VILLAGE HOUSING

The problem is that our 21 original village houses were placed without accounting for future expansion.

The current 9×10-tile living quarters module is essentially the footprint of another house. It is too large to serve as the only option for adding bedrooms to an existing home.

I do not want to solve this by arbitrarily relocating buildings, removing roads, or giving households free living space.

Approved direction

Implement appropriately sized additions that allow existing homes to expand when space permits.

1. Smaller attached rooms: A family should be able to add a bedroom or modest living-space extension without constructing another full-sized house.

2. Actual construction: Every addition requires appropriate materials, money where applicable, labor, and construction time. No free construction.

3. Existing ownership: Preserve the original house's ownership, household membership, and rent arrangements.

4. Available space: An addition may occupy legitimate buildable ground adjoining the house. It cannot overlap roads, occupied buildings, or another household's property without a legitimate ownership or land-transfer process.

5. Vegetation: Trees and removable vegetation may be cleared through normal gameplay before construction.

6. Alternative configurations: If a ground-floor addition is impossible, evaluate whether a smaller configuration or an upper-floor/attic conversion is practical. Do not invent an upper-floor system merely to bypass existing geometry.

7. No guaranteed expansion: A house that physically cannot expand must remain constrained. Its family can pursue another housing solution through the existing economic and household systems.

8. Persistent goals: A household must retain its housing objective when temporarily blocked. It should reconsider feasible options rather than repeatedly attempting an impossible placement.

9. Bed sharing: Preserve the approved and tested HOUSE-08 rules for couples and children.

Implementation boundaries

Before coding, inspect the existing house footprints and identify realistic room sizes that fit the current tile grid.

Use existing construction systems wherever practical.

Do not create a large new construction subsystem if a smaller extension module can solve the immediate problem.

Do not automatically convert every blocked household to a detached-quarters solution.

Build 15 acceptance

Verify that:

- Eligible original houses can receive legitimate expansions.
- Construction consumes actual materials and labor.
- New sleeping capacity becomes available only after completion.
- No roads, buildings, or neighboring parcels are overwritten.
- Ownership and household data remain consistent.
- NPCs can recognize when expansion is possible or impossible.
- Housing goals continue functioning without decision loops or permanent deadlocks.

Report how many of the 21 original houses can accommodate the approved smaller additions.

If some remain physically impossible to expand, report them accurately. Do not force a 100% success rate through unrealistic placement.

Continue the existing simulation and testing workflow.

PHASE 2 — FUTURE FULL PROCEDURAL VILLAGE GENERATION

This phase establishes design requirements only. Do not implement it during Build 15 unless the work is already independently approved and scheduled.

When we move into full procedural village and settlement generation, houses must be placed with future development in mind.

A procedurally generated village should not begin with every building packed so tightly that families cannot grow.

1. Expansion-aware house placement

When generating a house, evaluate:

- The house's initial footprint.
- Its land parcel.
- Road access.
- Available adjoining construction space.
- Terrain and elevation.
- Nearby buildings and property boundaries.
- Potential future bedrooms or extensions.
- Space for appropriate household activities.

The generator should consider both current occupancy and future household growth.

2. Realistic village density

I do not want every village to resemble a modern suburban subdivision.

Medieval settlements should have natural variation:

- Compact houses near central roads and marketplaces.
- Larger household plots toward the village outskirts.
- Workshops and trades near appropriate infrastructure.
- Farms and agricultural households with suitable land.
- Irregular roads and parcels that respond to terrain.

Not every home needs a large yard, but the village must have plausible ways to accommodate growing families.

3. Expansion opportunities

Generated homes should have one or more viable long-term housing options where practical:

- Attached ground-floor additions.
- Smaller room extensions.
- Upper-floor or attic development, if supported by the building system.
- Legitimate acquisition of adjoining land.
- Construction of a new family home elsewhere.

These options should be determined by the actual building and property systems, not by granting free housing capacity.

4. Reserve physical space during generation

The village generator should understand potential expansion footprints before placing neighboring buildings or roads.

Where appropriate, preserve usable ground around homes so that later construction remains possible.

This does not mean that every reserved area must remain permanently empty.

Households can use their land, vegetation can grow, and future construction may require clearing or reorganization.

However, the generator should not unknowingly eliminate every realistic expansion opportunity.

5. Village growth over generations

The starting village is not the finished village.

As families grow and new households form, settlements should be capable of expanding outward or becoming denser through legitimate construction.

New roads, homes, workshops, and other structures should respond to population needs, available land, resources, and household finances.

Village development should emerge from the actions of its inhabitants rather than an omniscient system automatically providing buildings.

6. Procedural validation

Before accepting a generated settlement, validate:

- Houses have legitimate road access.
- Parcels do not overlap illegally.
- Building footprints are valid.
- Essential routes remain traversable.
- Reasonable household expansion opportunities exist.
- Settlement growth is not immediately blocked by its initial layout.
- Terrain and resources support the intended settlement type.

Use configurable generation criteria rather than requiring every individual house to be expandable.

Test generated villages with different seeds, terrain conditions, and settlement densities.

7. Persistence and determinism

Procedural village generation must respect the game's established deterministic world-generation and persistence requirements.

Once a village exists, its buildings, parcels, modifications, ownership, and construction progress must persist.

Regenerating or loading a region must not overwrite player or NPC changes.

PROJECT MANAGEMENT REQUIREMENTS

Record the Phase 1 decision as the owner-approved resolution of OD-14.

Update the relevant housing specifications and development register.

Record Phase 2 as approved future design requirements under the appropriate procedural settlement-generation work. Do not silently assign it to Build 15.

If any part of Phase 1 requires a major new building system, identify the scope before implementing that portion. Continue other approved work in the meantime.

Keep approved development moving, preserve changes on remote GitHub branches, and follow the existing testing and staging gates.

No distributable build or release without my authorization.

CORE DESIGN PRINCIPLE

A medieval home is not a static object. It is a property that a family can improve over time through its own resources, labor, and decisions.

For the existing village, accommodate realistic improvements wherever possible.

For future procedural village generation, design the settlement intelligently from the beginning so families have room to grow.

Do not solve poor village placement by giving NPCs free houses, free bedrooms, or impossible construction.

The world must remain physically believable, economically consistent, and capable of evolving over generations.
