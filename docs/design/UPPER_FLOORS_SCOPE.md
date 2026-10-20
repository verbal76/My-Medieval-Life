# Upper floors and attics: scope estimate (HOUSE-11)

**Owner:** OD-14 Phase 1, item 6 (`docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md`): "evaluate whether a smaller configuration or an upper-floor/attic conversion is practical. Do not invent an upper-floor system merely to bypass existing geometry." On 2026-10-20 the owner chose to have a scope written for a later build, without starting it.

**Status:** estimate only. Nothing here is built or scheduled. The numbers are an agent's estimate, not measurements.

## Why it matters

Measured on the current village, a ground-floor addition fits beside 3 of the 21 original houses; the other 18 are hemmed in by the map edge, neighbours, the road, the manor's fields and the cow pen (`docs/release/LONG_RUN_SIMULATION.md`, "OD-14 Phase 1"). An upper floor or attic adds sleeping space inside a house's own footprint. It is the only expansion that does not need ground.

## The building system today (read in the code)

- **Map:** `VillageMap` (`game/scripts/core/village_map.gd`) is one grid. Each cell is solid or walkable; tiles are drawn in named layers (ground, below, above, roof). Pathfinding is one `AStarGrid2D` over that grid (`find_path`).
- **Buildings:** a building is a stamp: tile layers, a collision mask and an interior (area, floor, doors, roof cells, spots such as beds and tables). Every stamp is the 9x10 house drawn by Shade, made into stamps by `tools/build_village.py` (`workshop_stamp`).
- **Inside a building:** people inside walk the same grid. The roof over them fades (`view/roof_fade.gd`, `World.roof_over`), so the interior shows.
- **Positions and saves:** people, animals and items have a 2D position only. Saves store x and y with no level.

There is no notion of a level anywhere: not in positions, the map, pathfinding, drawing or saves.

## What an upper floor would need

| Part | Work | Size estimate |
|---|---|---|
| Level in positions | A floor index on NPCs, the player, items, beds and stations; saved and migrated (a save-format version with a migration, CLAUDE.md section 7) | Medium |
| Map per level | A second grid for each building's upper floor (its own solid mask and tiles), held per building, not for the whole map | Medium |
| Stairs | A stair spot in the house interior: a station that moves a person between levels; pathfinding across levels (to the stairs on one level, from them on the next) | Medium–large: every route to a bed upstairs becomes two searches |
| Drawing | Show the upper floor when the player is up there (hide the ground floor and its people, as the roof fade does today); the camera and HUD unchanged | Medium |
| Art | Floorboards, stair and attic wall tiles in Shade's style: check the owned packs first (asset pipeline); otherwise a gap to record | Unknown until the packs are searched |
| Construction | An "attic" module built on top of an existing house (materials, labour, time) by the existing site and delivery rules; its beds count only once finished | Small: reuses the module path |
| AI | Beds upstairs in `beds_in`; NPCs path to them through the stairs; fires, theft and witnesses work per level | Medium |
| Tests | Save migration, two-level paths, crowding with attic beds, determinism of the long runs | Medium |

**Overall:** a multi-level building system is a major addition, touching the map, positions, pathfinding, drawing, saves and the AI. As a rough estimate (not measured), it is about the size of the carts work (B14-6) or larger. It belongs in its own build, after Build 16's baseline, alongside procedural village generation (PVG-03 lists upper floors "if supported by the building system").

## Cheaper intermediate options (for the owner to weigh)

1. **Sleeping loft, no second level.** An "attic" upgrade adds beds that count in `beds_in`, with a ladder spot inside the house. Nobody walks on an upper grid: a person "goes up to bed" at the ladder and is drawn as asleep there. It costs materials and labour as a module. No level is added to positions, pathfinding or saves. **Small–medium. It does not create walkable upper floors,** so it is a bed-count improvement, not real architecture. It needs the owner's approval as a design choice.
2. **The 5x6 ground-floor room** for the 3 houses with room (HOUSE-10, not built).
3. **Nothing more for original houses.** Bed sharing (HOUSE-08), households splitting and new homes carry the growth.

## Risks

- **Saves:** a level field in every position is a save-format change, which needs a migration from every released version.
- **Determinism:** two-level pathfinding changes how routes are found, and with it the outcome of the long runs for the same seeds. That would be recorded as a deliberate change.
- **Performance:** routes to upstairs beds double the pathfinding calls for those trips, and PERF-01 already measures the simulation 4–5 times slower than the historical benchmark.
