# Owner directive, 2026-10-21: MIN-F2 Owner Decisions (mining equipment production; collapse consequences; future health system)

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

MY MEDIEVAL LIFE — MIN-F2 OWNER DECISIONS

Claude, the owner has answered both outstanding MIN-F2 questions.

Record these decisions in the requirements register and decision ledger. Apply the Build 17 scope boundaries below.

MIN-F2-Q1 — Mining equipment production

APPROVED FOR BUILD 17

Both carpenters and smiths must participate in the legitimate production of mining equipment.

This includes:

- Timber supports.
- Ladders.
- Minecarts.
- Appropriate metal components, fittings, and fasteners.
- Replacement components and repair materials.

Use the existing crafting, inventory, production, trading, and job-board systems wherever possible.

Carpenters should produce appropriate wooden components and assemblies. Smiths should produce appropriate metal components and assemblies. The exact production responsibilities should reflect the equipment's actual material requirements.

Not every item needs to visit both professions if its construction does not require both. However, neither profession should be arbitrarily excluded from producing equipment or components appropriate to its trade.

All manufacturing must consume actual materials, labor, and time. No free equipment, instant production, or artificial supply.

Equipment should become available through ordinary market transactions and legitimate procurement.

The manor may purchase needed equipment and arrange support repairs through existing systems, using actual treasury funds.

NPCs must be able to obtain equipment without depending on the player to manufacture or supply everything.

Do not create a mining-specific economy or a separate artificial wage system.

Keep implementation focused on enabling the existing underground mining system to function independently.

MIN-F2-Q2 — Collapse consequences and future health system

BUILD 17 DECISION: BINARY SURVIVAL OR DEATH

For Build 17, a character caught in a mine collapse can either:

1. Survive.
2. Die.

Do not introduce a partial injury or recovery state in Build 17.

Do not implement a new medical subsystem, hospital, injury-treatment system, or recovery simulation as part of this task.

The survival/death determination must be deterministic for equivalent simulation state and seed, and must reflect the established collapse mechanics.

Deaths must use the existing legitimate NPC death and consequence systems. Do not simply delete an NPC without applying existing death handling.

Survivors must be handled consistently with the physical world. Review the current behavior that moves trapped people to the nearest open floor. Do not silently retain an unexplained teleportation mechanic. Use an existing valid survival or displacement mechanism where possible, and report any limitation requiring a future rescue system.

Do not invent an arbitrary survival percentage as permanent owner policy. If a temporary tunable value is necessary, document it and identify it for later review.

FUTURE EXPANSION — HEALTH, INJURY AND MEDICAL SYSTEM

APPROVED FOR FUTURE DEVELOPMENT. NOT BUILD 17.

Create a tracked requirement for a broader medieval health and medical system.

The owner wants genuine consequences from accidents, illness, and physical injury, but the system must fit the medieval setting.

This is not a modern hospital simulation.

The game already has an apothecary and potions. Audit those existing systems before designing the expansion.

The future design should consider:

- Injury severity and bodily health.
- Accidents, including mining collapses.
- Illness and disease.
- Bleeding, infection, and recovery where appropriate.
- Medieval medical treatment and available practitioners.
- Apothecary products and existing potions.
- Treatment costs and availability.
- Rest, labor limitations, and recovery time.
- Permanent disability or lasting consequences where appropriate.
- Death when injuries or illnesses prove fatal.
- NPC decisions concerning treatment, work, risk, and affordability.

These are design considerations, not authorization to implement all features immediately.

Do not assume every injury is treatable or every patient survives.

Medical care must operate within the village economy, including real supplies, practitioner availability, costs, and time.

Preserve the existing apothecary and potion systems. Extend and integrate them rather than replacing them unnecessarily.

Record dependencies on NPC behavior, mortality, occupations, economics, and future simulation systems.

BUILD 17 EXECUTION BOUNDARY

Complete the narrow mining-equipment production and procurement integration.

Implement only the binary collapse survival/death behavior needed for Build 17.

Defer the comprehensive health system.

Run focused tests for equipment manufacturing, supply, procurement, collapse outcomes, conservation, determinism, and existing death handling.

Reuse existing passing test evidence where applicable. Do not rerun unrelated full suites unnecessarily.

Do not allow the future medical expansion to delay MIN-G, final CI, or Build 17 completion.

Report the implementation status, any unresolved technical blockers, and the updated Build 17 completion path.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
