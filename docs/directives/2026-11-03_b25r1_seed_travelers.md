# Owner directive, 2026-11-03 (received about 13:00 EST): Build 25 Revision 1, seed travelers

Saved verbatim. Register: B25R1-009.

---

BUILD 25 REVISION 1 — OWNER DIRECTIVE: SEED TRAVELERS

Approved design clarification — incorporate into the current wilderness NPC implementation.

All roaming people encountered outside settlements must be real members of the existing living-world simulation.

Do not create disposable, randomly generated roadside NPCs or decorative travelers.

1. Every traveler belongs somewhere

Each traveler must:

- Have a real home settlement.
- Belong to that settlement's population and household/social systems as applicable.
- Have a persistent identity and normal NPC state.
- Participate in the existing economy, relationships, employment, reputation, mortality, and other applicable systems.
- Retain their home and normal life when traveling.
- Be able to return home and resume ordinary activities.

Travel must be an activity performed by an existing person, not a separate NPC category with simplified simulation rules.

2. Initial seed travelers

At world initialization, designate a small, configurable number of legitimate residents from existing settlements as initial travelers.

These are seed travelers, intended to establish visible activity between settlements before naturally generated travel becomes common.

Each seed traveler must:

1. Have a real home settlement.
2. Select another existing settlement as a destination.
3. Have a simple initial purpose: travel there to purchase one ordinary, available trade item.
4. Carry or have legitimate access to the money needed for the purchase.
5. Physically travel along the existing road and trail network, using normal movement and routing rules.
6. Interact with an actual merchant and complete a normal economy transaction.
7. Return to their home settlement with the purchased item.
8. Resume normal life afterward.

Use existing inventory, pricing, money transfer, trade, pathfinding, and NPC behavior systems. Do not create artificial purchases or free items.

If the item is unavailable, the merchant is closed, or the route is blocked, use sensible existing fallback behavior rather than inventing a successful transaction.

3. Natural travel afterward

Seed travelers are only the starting population of travelers.

Additional intersettlement travel should emerge organically from the existing economy and NPC motivations.

Do not create a permanent artificial stream of travelers solely to make roads look busy.

Do not repeatedly force the same seed residents to travel unless their ordinary simulation behavior gives them a new reason.

4. Population integrity

- Do not duplicate NPCs when they leave or enter a settlement.
- Do not remove travelers from their home population records.
- Do not create extra people or currency to support travel.
- Preserve traveler identity, inventory, relationships, and economic state across regional transitions.
- Persist travel destinations and progress through save/load.
- Ensure travelers can be encountered and interacted with on the road.
- Apply normal danger, combat, injury, and mortality rules.
- Preserve deterministic simulation behavior.

Travelers must be genuine people, not moving scenery.

5. Validation

Test at least one complete seed-traveler journey:

Home settlement → road travel → destination settlement → legitimate purchase of one item → return home → resume ordinary life.

Verify that:

- The NPC retains the same identity throughout.
- The purchase transfers actual money and goods.
- The NPC remains interactive while traveling.
- Population counts remain correct.
- Save/load works during travel.
- No resources or currency are created or destroyed improperly.
- Normal simulation behavior resumes afterward.

Document the implementation and evidence under Build 25 Revision 1.

Design principle: We are seeding reasons for existing people to travel, not seeding fake people into the countryside.
