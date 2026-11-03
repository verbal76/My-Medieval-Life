# Roads and trails audit, Build 25 Revision 1 (B25R1-004)

Owner directive 2026-11-03 (`docs/directives/2026-11-03_b25r1_master_directive.md`, section 2): "Audit the existing road and
trail implementation before changing it ... Determine which road types are currently implemented, generated, rendered, and
traversable ... If either expected road type is missing or nonfunctional, identify the gap ... Do not fabricate decorative
roads." Audited on `wip/expansion20` at `a459186`, branch `wip/b25r1-map`.

## What exists

| Layer | Where | Road kinds |
|---|---|---|
| Village streets | `game/data/village.json` `road` and the `path` layers, built by `tools/build_village.py` (generator v10) from the Puny World "pathways" wangset | One: **dirt** (`dirt-paths`). Door trails (`door_trails`) are drawn dirt paths that are not walking roads. |
| Overworld road network | `game/scripts/core/overworld.gd`: road nodes on a jittered 96-tile grid (`node_pos`), edges east, south, south-east, south-west by hash (`_edge`), a bent 4-connected polyline per edge (`_polyline`) | One tile kind: **dirt** (`overworld_tiles.json` `dirt_path`, the same wangset). |
| Gate and settlement links | `Overworld._setup_gates`, `_setup_sites`: each village gate and each settlement joined to its three nearest road nodes (`_links`) | The same dirt tiles. |
| Region map | `scripts/ui/region_map_view.gd` | Before: roads only inside explored chunks, as a summary class. Now: every segment, two drawn kinds (below). |

- **Generated:** every chunk rasterises the segments that touch it (`_road_mask`), so roads cross chunk seams unbroken; a road
  never runs through the village or a settlement site (their own roads join the network). Deterministic from the seed.
- **Rendered:** in the world as the dirt pathway tiles (`Overworld._generate`, `_road_bits`). Before this revision the Region
  map showed a road only in an explored block (Atlas class ROAD).
- **Traversable:** a road cell and one tile round it never hold a cliff, tree or rock (`_generate`: the `open` margin), so every
  road cell is walkable. `region_travel_test` samples 239 road cells drawn on the map: all are road cells of the world and none is
  solid. `overworld_test` and `region_geography_test` already prove every settlement reachable on foot from the village by road.
- **Connected:** the village's four gates and all five settlements are on one network; `Overworld.route_between` finds the road
  route between any two (the regional trade and the couriers measure distances by it; NPC journeys walk it,
  `Journeys.resume`). `region_travel_test`: the road route from the south gate to each settlement is found and lies entirely on
  the roads classified "road".
- **Movement rules:** no speed bonus or penalty depends on road cells (the player and NPCs walk at the same speed on and off the
  road); roads matter for route choice (NPC journeys use only roads; the player's travel prefers them).

## Findings

1. **Stone roads did not exist** (before B25R1-Q1, below) in the game data or the art in use. Both shipped tilesets' road wangsets offer dirt, sand and
   water paths only (`tools/puny_world_terrain.py`: the "pathways" edge wangset has `dirt-paths`, `sand-paths`, `water-paths`);
   the only grey cobbled art in the project is the quarry slab (`ROCK_SLAB`, used for pits and mine floors), not a road autotile.
   No design document or register entry defines a stone road. **Gap: owner decision or art needed** to add stone roads in the
   world (choose a stone road tile set from the owned packs, or accept the sand path as the "made road"); either changes the
   overworld's drawn tiles (a generator visual version) and is outside this worker's scope. Nothing was invented.
2. **Two functional kinds already exist in the network's structure, but were indistinguishable:** the roads that join the
   places (the routes between the village gates and the settlements) and the rest of the network, which leads off into the
   country. Correction made (within the approved navigation design, from the real data only): `RegionRoads.kind_of` classifies
   each segment "road" when most of its cells lie on a route between two places (`RegionRoads.main_cells`, from
   `Overworld.route_between`), "trail" otherwise; the Region map draws roads wide and pale, trails narrow and brown, with a
   legend. In the world both remain the same dirt path tiles (finding 1).
3. **Roads were invisible on the map until explored.** Correction: `RegionRoads.segments` lists every segment in an area from
   the road data itself (no chunk generated), by exactly the rules of `_road_mask`, and the map draws them from day 1. Cells
   inside the village are not drawn (the world does not stamp road there either: `Overworld._stamp`).
4. **Some road polylines pass over village cells** (seen on the first map drawing: a gate's link from its far point to a road
   node is not checked against the village rectangle, and a bent polyline can wander up to 9 tiles off its nodes' box). The
   world never stamps road inside the village (`Overworld._stamp`), so the playable world is consistent; the map now leaves
   those cells out the same way. No change to generation (it would alter existing worlds); a walking route along such a link
   simply crosses the village's own ground, which is walkable.
5. **Streaming continuity:** roads are rasterised per chunk from global segments, so they meet across chunk seams; nothing in
   this revision changes chunk generation, and the map's lines come from the same segments.

## Owner decision B25R1-Q1 (2026-11-03) and what was built

"Option 2, with a realistic road hierarchy. Add stone roads using suitable existing stone artwork where possible ... three
recognizable road types: 1. Stone roads ... 2. Dirt roads ... 3. Dirt trails ... Do not convert every intersettlement road into
stone. Reuse the existing road network, navigation, and movement systems." Built on `wip/b25r1-roads`:

- **Art** (`tools/road_tiles.py`, run by `tools/import_game_assets.py`; `game/assets/tiles/road_tiles.png`, provenance recorded):
  the free tileset's 16 dirt path tiles (the shapes the world already draws, grass edges included) with their dirt replaced by
  the paid Puny World tileset's flagstone ground (tiles 10150, 10151, 10370, 10371) and the rim darkened into a kerb: 4 paving
  variants; and the same tiles narrowed by one ring with tufts of grass through the dirt for trails: 2 variants. No pack's
  outdoor road art exists (the stone families are floor-and-wall blocks with wall rims, which would read as building blocks),
  so the stone is set into the road's own shapes.
- **Placement** (`RegionRoads.main_kinds`, `lane_cells`, `cell_kind`; pure functions of the seed, cached): **stone** on main
  road cells within 24 tiles of the village or a settlement (the approaches) and on the most travelled stretches (14 or more of
  the 30 routes between places pass along them), plus each settlement's street (the middle row of each lane its doors open
  onto); **dirt road** on the rest of the main roads; **trail** on every other road cell. Seed 1: 1,213 of 6,297 main road
  cells stone (19%), 504 street cells. The overworld has no rivers, so there are no bridges or fords to pave.
- **Drawing only:** `OverworldView.road_tile` chooses the tile for the same cells (atlas 4 of `MapView`); chunk data,
  `GEN_VERSION`, walkability, routes and saves are unchanged. The village's own streets are left as they are.
- **Map:** three line styles and a legend (Stone road, Dirt road, Trail), split cell by cell by the same `cell_kind`.
- **Checked:** `game/tests/road_types_test.gd` (all three present; stone not most of the main roads; every settlement
  approach paved; every sampled cell of every type open road with the world's type; each type drawn with its own tiles in the
  view and in a built chunk; the map's types match the world's; one journey walks over all three). Screenshots
  (`game/tests/road_types_shot.gd`): a settlement street, stone giving way to dirt road, a dirt road, a trail; the map at
  1280 x 720 and 2400 x 1080.

## Not changed

- No generator version bump, no tile change, no new road. NPC journeys and the regional trade's distances are unchanged.
