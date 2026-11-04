# Water: streams, rivers, waterfalls, fords and bridges (B25R1-Q3, B25R1-017)

Owner decision B25R1-Q3 and directive B25R1-017 (2026-11-03,
`docs/directives/2026-11-03_b25r1_integration_water_directive.md` on `wip/requirements-control`, sections 3-5 and 7), and
the owner's follow-up: "we need rivers and streams, we might as well do them now ... the water needs to be flowing". The
code is `game/scripts/core/overworld.gd` (the section "water"), the art `tools/water_tiles.py`, the tests
`game/tests/water_test.gd`. Numbers are agent decisions (`docs/DECISIONS.md`, 2026-11-03).

## 1. What a world holds

- **Generation.** Water exists from overworld generation 4 (`Overworld.GEN_VERSION`). A world keeps the generation it was
  made with (`Overworld.gen`, saved as `overworld.gen`): a save of generation 1, 2 or 3 is drawn by generation 3 exactly as
  before, with no water (checked by golden chunk hashes recorded before the change), and relies on wells (the homestead
  workstream). No waterway is ever drawn into an existing world.
- **Courses.** Global features like the roads, so they cross chunk seams unbroken. Each course (`Overworld.river_at` and `stream_at`, keys:
  `id`, `order`, `pts`, `r`, `heading`, `pools`, `falls`, `fords`, `joins`, `length`, `box`):
  - rivers (order 2): one may rise in each 352-tile lattice cell (65%), on high ground; up to 110 steps of 6 tiles; 1.6 tiles
    wide at the spring, widening to 3.4; ending in a lake;
  - streams (order 1): one may rise in each 176-tile lattice cell (70%), at a spring on the mountains or else on high ground;
    up to 48 steps; 0.8 to 1.7 wide; a stream that reaches a river ends in it (`joins`): a connected network;
  - both run downhill on the mountain field (`_height`), at most 60 degrees a turn, meandering; end in a pool where the ground
    rises all round; keep 20 tiles from the village and every settlement.
- **Per cell** (`Overworld.Chunk`): `water` (1 stream or pool, solid; 2 bridge; 3 waterfall, solid; 4 ford, walkable), `flow`
  (the downstream direction 1-8: E, SE, S, SW, W, NW, N, NE; 0 still in a pool; 9 foaming in the pool below a fall), `level`
  (the course's order: 1 stream, 2 river) and, for dry cells near the water, `bank` (the height above the water's edge in tiles,
  1-6: the floodplain; 255 beyond). Generated from the seed, never saved, independent of the order chunks are made in.
- **Waterfalls** only at genuine drops: a cliff rim cell the water runs through where a mountain top lies above it and low
  ground below (the rock face is drawn on the south side). Elsewhere a course cuts through the rim as water.
- **Crossings.** A road cell on water is a bridge (walkable): plank on dirt roads and trails, stone on stone roads, one bridge
  laid one way (its planks run the long way of the crossing). Every road crosses a course on one straight, axis-aligned leg
  square to the course's main direction, from 2 tiles clear of the water on one bank to 2 clear on the other
  (`Overworld._crossing_legs`, applied to every road's cells as `_polyline` draws them; a layout crossing fixes the leg's line
  through its point), so a bridge or ford is one straight run and the road turns on dry land. Water never lies along a road: it
  may cross a road only at 37 degrees or more to the road's own line, else the road keeps to the bank, dry; pools keep off roads. Every 4 steps (about 24
  tiles) off the mountains a ford: shallow water with stepping stones, walkable, so no course walls a stretch of country off;
  a ford is a band straight across the course (`water.json` `ford_band`, half-width 1.3 tiles), a line of stones from bank to
  bank, not a field of them. A canonical ford keeps its stones on the road (its edges shallows).
  The tile beside a road is kept walkable too: water there that flanks no crossing is shallows (`water` 4, no stones drawn), so
  a road beside a course is never pinched; only the deep water either side of a bridge or ford lies next to a road.
- **Tuning in one place (EA-01).** The numbers above (lattices, chances, steps, widths, end pools, meanders, ford spacing and
  radius, bank reach, rocks, the road-crossing angle as a sine, 0.6 = 37 degrees: crossings are straight legs, so a course meeting one at 45 degrees still crosses) live in `game/data/water.json`
  (`mml-water/1`), read once by `Overworld.water_cfg`. The sound distances are `music.json "water"`; the art's ripple and foam
  are `tools/water_tiles.py`'s. Changing `water.json` changes generation 4's water for every world (water is never saved).

## 1a. The canonical water (B25R1-018)

The region layout (`game/data/region_layout.json`, `mml-region-layout/1`, owned by the region workstream; the water reads its
`rivers`, `crossings`, `downs` and `landmarks`)
anchors the network on Morris's geography, in absolute overworld tiles of the village frame (12 tiles a mile):

- `rivers[]` `{id, name, order, width, points [[x, y]...] upstream to downstream, joins, passes_settlement}`: traced through
  the points by the generator's own meander (`Overworld._trace_through`: a bend that is nought at every point, so the course
  passes through each exactly), widening slightly downstream, with fords, pools and falls as every course has. Upmeads Water
  (order 3) runs west to east past the village; the Netherton stream rises at the Downs' foot and joins it; Coldlake laps
  round Higham and crosses the south road three times. A course that passes a settlement (`passes_settlement`) may come within
  the clearance, never onto the settlement's built ground (its site and a tile round it).
- `crossings[]` `{kind ford | bridge, x, y, course, material}`: where a road crosses the course there, the road keeps that
  crossing: a ford (walkable shallows with stepping stones, on the road), a bridge of the road's type, or stone when the
  material is stone (`Overworld.forced_crossing`).
- `downs` `{rect, polygon, springs: none, water_ok}`: the waterless Downs (`Overworld.in_downs`): no generated stream rises or
  runs there; its one water is the landmark it names (the chapel pool, a still pool).
- Generated streams and rivers fill in elsewhere and may end in a canonical river. The layout's courses follow the novel
  rather than the mountain field, so the "downhill" rule is the layout's own direction for them.

## 2. Using it

- `Overworld.is_water(cell: Vector2i) -> bool` (a stream, pool, waterfall or ford; a bridge is not water) and
  `Overworld.nearest_water(cell: Vector2i, radius: int) -> Vector2i` (`Vector2i(1 << 30, 0)` = `Overworld.NO_WATER` when none,
  always for generation 3): the homestead workstream's agreed signature, streams and rivers only. Also
  `nearest_water_access(cell, radius, wells := Callable())` (the open bank cell beside the water, to stand on and drink; with
  `wells`, the one well registry's lookup `w.wilds.wells_near`, a nearer well wins: Overworld keeps no well data), `is_bridge`, `is_ford`, `flow_at`, `water_level`, `bank_height`, `nearest_fall`, `crossing_id`.
- Walking: water and waterfalls are solid in `Overworld.is_solid`, so every path-finder (VillageMap.find_path_world, NPC
  walks, RegionTravel) goes round them or over a bridge or a ford.
- The Region map draws the courses (rivers wider), pools and bridges from the course data, without generating chunks.
- Sound: the audio's water layer plays a stream or river loop and a waterfall loop by the player's distance
  (`GameAudio.set_water`, `music.json "water"`; Minifantasy: Forgotten Plains SFX).
- Flight recorder (`WaterNotes`; the recorder's own vocabulary, `recorder_codes.json`): `bridge_used` (a person crossed a
  bridge, once a person, bridge and day; object and place `crossing:bridge:<x>,<y>`, the bridge's first cell: stable),
  `route_crossing` (a planned route crosses water: chosen bridge, ford or detour, alternatives, counts),
  `travel_blocked_by_water` (a trip refused or a walk given up because of water: outcome failed, reason no_crossing).

- Live range (B25R1-019): water animates and is heard only inside the player's live range. The animated tiles are drawn
  only in the chunks loaded round the camera (OverworldView), and the sound asks `Main.water_live(cell)`, the one call site
  that switches to the presence workstream's query when it lands. The water data itself is permanent.

## 3. Extension points for weather, rain, flooding and seasons (not built now)

The water is constant in Build 25 Revision 1. A later weather expansion adds behaviour through these, replacing nothing:

| Hook | What it is | Now |
|---|---|---|
| `Overworld.seasonal_flow` | a factor on every course's flow and level (seasons) | 1.0 |
| `Overworld.water_level(cell)` | the level a system reads: an override, else the cell's `level` x `seasonal_flow` | constant |
| `Overworld.set_level(cell, level)` | where rain or a flood writes a cell's level (`level_override`) | never called |
| `Overworld.on_level_changed` | a Callable told `(cell, old, new)` by `set_level` | unset |
| `Overworld.bank_height(cell)` | how far above the water a dry cell stands: a rising level reaches it at that height | read only |
| `Overworld.course_graph(area)` | per course: order, joins, tributaries, length, catchment (own length plus its tributaries'), flow (order x seasonal_flow) | read only |
| `Overworld.flow_at(cell)` | the direction the water runs (for currents, drift, flood spread downstream) | read only |

What a weather system will still have to decide (and own): what a raised level means for walking (a flooded bank cell turning
solid), drawing (`OverworldView` would redraw cells whose `water_level` changed; `on_level_changed` is the place), saving
(`level_override` is not saved yet) and the economy (crops on the floodplain). Determinism holds as long as every change comes
from the world's own clock and seeded state.

## 4. Art

The free Puny World tileset's own grass/river corner set (the tileset the overworld's grass and cliffs are drawn with), its
waterfall, pebbles, wooden walk and castle wall-walk, through `tools/water_tiles.py` (`game/assets/tiles/water_tiles.png`,
provenance recorded; its layout read by `tools/build_overworld_tiles.py`). EA-01 (owner, store quality):
- **Flowing water** is the set's own tiles with their open water replaced by three long, soft ripples of the set's lighter
  water colours, drawn along the flow and scrolled 2 px a frame downstream (eight frames of `water.json` `frame_seconds`,
  0.18 s: about 11 px a second, a seamless loop). Two looks with the ripples in other places are picked per cell
  (`Overworld._water_cell`), so no lattice of streaks shows. Pools keep the set's shimmer, held two frames a step.
- **Waterfalls**: the rim's fall has its splash cut so it runs on into the cell below, its foot (`fall_foot`: the fall's
  lower cascade, its splash, foam): two cells tall at every fall; the pool below foams, its flecks drifting south.
- **Bridges** are the tileset's own walks: wooden (rails both sides, the north end capped with posts, the south end on legs
  in the water; east-west the rounded ends; `OverworldView._bridge_tile` picks the end pieces) and, for stone, the castle
  wall-walk with crenellated parapets both sides. The plank and stone tiles replace the earlier flagstone with darkened edges.
- **Shores**: the set's corner tiles step at 45 degrees; look 1 sets a small tuft of the set's bank grass where a corner
  tile's shore turns, softening the steps (the art's own corners decide where). The Forgotten
Memories water (owned) has rock shores in another palette on a 32 px grid and was not used beside this grass; Miniworld's
Cliff-Water likewise belongs to the Miniworld look.
