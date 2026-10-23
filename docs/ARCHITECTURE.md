# My Medieval Life: architecture proposal

Status: **proposal, awaiting owner approval** of the engine (U2), the primary platform (U1) and the
core mechanics (U3–U5 in `docs/GAME_DESIGN.md`). No engine project exists yet, and none should be
created until these are approved.

## 1. Engine assessment

What the engine must handle (from the assets and the confirmed requirements):

- 16x16 pixel art at integer scale with nearest-neighbour filtering
- Corner and edge based autotiling: the Puny World tileset's wangsets, which the Python generator
  already uses
- Deterministic procedural maps, ideally generated at runtime from a seed
- Directional sprite animation from frame rectangles (`data/miniworld_animations.json`, Puny
  Characters sheets)
- Placing multi-tile buildings (`data/miniworld_buildings.json`)
- Versioned save files
- Android and desktop builds (which one is primary is undecided)
- Headless builds and tests in CI, because most code will be written by agents
- An owner who describes themselves as a beginner (per the Climb up project) must be able to open,
  run and inspect the project

| | **Godot 4** | GameMaker | Unity | libGDX |
|---|---|---|---|---|
| Cost and licence | Free, MIT | Free for non-commercial use; commercial export needs a paid licence | Free tier with a revenue cap; proprietary | Free, Apache 2 |
| Pixel-art 2D | Built in (nearest filter, integer scaling, `TileMapLayer`) | Strong, 2D-first | Good, needs setup (Pixel Perfect Camera) | Manual but straightforward |
| Autotiling | Terrain sets with corner/side matching, the same idea as the Tiled wangsets used here | Built-in autotile works on its own 16/47-tile layouts, not wangsets | Rule Tiles (package) | Write it yourself |
| Tiled maps | Community importers; we can also feed our own JSON directly | No native import | SuperTiled2Unity (community) | Native TMX loader (our tools write TMJ, so TMX output would be needed) |
| Runtime generation | GDScript or C#; easy to port the Python generators | GML; port possible | C#; port possible | Java/Kotlin; port possible |
| Animation | `SpriteFrames`/`AnimationPlayer`, or regions straight from our JSON | Sprite strips; would need to slice sheets | Animator; heavyweight for this | Manual from regions; simple |
| Save data | JSON/`FileAccess`, easy | `json_stringify`/buffers | JSON/serialisers | JSON (libGDX `Json`) |
| Android + desktop | Both from one project; headless CLI export | Both, licence tier dependent; CLI builds awkward | Both, mature; CI needs licence activation | Android first-class; desktop via LWJGL3 |
| Headless CI and tests | `godot --headless` for export and tests (GUT or gdUnit4) | Weak: builds tied to the IDE and licence login | Possible via GameCI, slow and heavy | Excellent: Gradle + JUnit |
| Agent-friendly files | Text scenes (`.tscn`) and scripts | JSON `.yy` files, but IDE-centric | Large YAML scenes and meta files | Plain code only |
| Owner can inspect visually | Yes (editor) | Yes (editor) | Yes (editor) | No editor |
| Multiplayer later | Built-in high-level networking (ENet/WebSocket) | Low-level networking | Netcode packages | KryoNet etc. (third-party) |
| Project weight | Light (one ~100 MB editor binary) | Medium | Heavy | Light |

### Recommendation: Godot 4 (GDScript)

- **Fit with the assets:** its terrain sets match the corner/edge wangset model the generator
  already uses, and pixel-art rendering works without workarounds.
- **One project for Android and desktop,** with headless export and test runs in CI. Agents can work
  on plain-text scenes and scripts.
- **Free and open source,** with no licence tiers or revenue caps that could block a commercial or
  Android release later.
- **It has an editor,** so the owner can open the project and see the world, which matters for a
  beginner who must approve what is built.
- **Room to grow:** built-in networking leaves multiplayer possible if U9 ever needs it, without
  building for it now.

**Strongest alternative: libGDX,** if the owner prefers to reuse the Climb up toolchain or wants a
code-only project. It costs more boilerplate and has no editor. GameMaker's licence-gated CLI builds
and Unity's weight are poor fits for an agent-driven, CI-built project of this size.

## 2. Platform

**Recommendation:** make Android (landscape, touch) the primary target **if the owner confirms
U1**, since that is the owner's precedent. Use a desktop build (Linux or Windows) as the
development and CI test target from day one either way: it is the fastest to iterate on and the
only one testable headlessly. The input layer is built so touch and keyboard/mouse are both
first-class, so changing the primary platform later is cheap.

## 3. System layout (engine-neutral; Godot names in brackets)

```
game/                       (created only after approval)
  core/      pure logic, no engine rendering: rng, world model, generator port, save format
  world/     rendering of the world model: tile layers, objects, chunks   [TileMapLayer]
  actors/    player and other entities: movement, animation, collision    [CharacterBody2D]
  input/     action mapping for touch + keyboard/mouse                    [InputMap]
  ui/        HUD, menus (minimal until mechanics are approved)
  data/      imported JSON from /data plus generated import manifests
  tests/     headless tests                                               [GUT / gdUnit4]
tools/       Python reference generators and asset tooling (unchanged)
```

Rule: `core/` never depends on rendering. Generation, save/load and (later) any simulation run and
are tested without a window. This is what keeps determinism and testing cheap.

### 3.1 Procedural world generation and seeds

- The generator produces a **world model**: per-cell tile ids for the ground, trees and bridges
  layers, plus features (sites, rivers, roads, bridges). This is the same content the Python tool
  writes to `.tmj` and `features.json` today.
- **Port to the engine** (needed for runtime generation, which depends on U5):
  1. Switch the Python reference from `random.Random` (Mersenne Twister) to a small, fully specified
     PRNG (PCG32) that can be implemented bit-identically in GDScript. This is a generator version
     bump (v1 → v2).
  2. Port the generator to `core/`.
  3. A test generates golden seeds in both implementations and compares tile data byte for byte.
     The port does not ship until this passes.
- **Alternative if U5 says the world is fixed or pre-built:** ship maps generated by the Python tool
  as data and skip the port. The `WorldSource` interface below allows either.
- `WorldSource` interface: `generate(seed, params) -> WorldModel` or `load(path) -> WorldModel`.
  Everything downstream consumes `WorldModel` only.

### 3.2 Terrain and tile rendering

- Import the Puny World tileset once as a tileset resource. The generator already resolves every
  cell to a concrete tile id, so the engine places ids directly and **does not re-run autotiling**.
  This guarantees the engine shows exactly what the generator validated.
- Three layers, matching the `.tmj`: Ground, Trees (overlay), Bridges (overlay). Tile animation
  (water, from the tsx `<animation>` entries) is imported with the tileset.
- Large maps are split into chunks of 32x32 cells; only chunks near the camera are kept in the scene.

### 3.3 Character animation

- The animation player reads frame rectangles and timing from JSON (`data/miniworld_animations.json`,
  plus an equivalent file for the Puny Characters sheets) instead of hand-made engine resources, so
  the data stays generated from the source art.
- A frame is drawn at `position - origin` (see `docs/ASSET_DATA.md`). Direction is chosen from the
  movement vector: 4-way for Miniworld, 8-way for Puny Characters.

### 3.4 Input and camera

- Logical actions (`move`, `interact`, `menu`) are mapped to keyboard, gamepad and touch (virtual
  stick). Gameplay code reads actions only.
- The camera follows the player, is clamped to the map bounds, uses integer-pixel scaling and snaps
  to whole pixels to avoid shimmer.

### 3.5 World objects, buildings and entities

- Buildings come from `data/miniworld_buildings.json` (name, sprite rect, team colour) or the Puny
  World tileset's building tiles. Which family is used is design question U13.
- Each placed object records its type id, cell position and footprint in cells. Footprints come
  from the sprite rect (16px per cell).
- Entities are plain engine nodes with a stable `entity_id` for saving. No ECS framework: the scale
  doesn't justify one.

### 3.6 Collision and navigation

- Collision comes from tile data: water, deep sea, tree overlay cells and building footprints are
  solid; roads, bridges, grass, sand and dirt are walkable. A per-tile `walkable` flag is set in the
  imported tileset by tile category, generated from the same wangset data.
- Navigation (only if NPCs are approved): a grid-based A* over the walkability grid, the same kind of
  grid search the generator's road router already uses.

### 3.7 Save/load

- One JSON file per slot:

  ```jsonc
  {
    "save_version": 1,
    "game_version": "0.1.0",
    "world": { "generator": "puny_world", "generator_version": 2, "seed": 1, "params": { ... } },
    "player": { "x": 0, "y": 0, "facing": "down" },
    "world_changes": []
  }
  ```

- The world is regenerated from the seed on load, never stored, unless a future generator change
  makes that impossible (see the save rules in CLAUDE.md, section 7).
- Writes go to a temporary file and are then renamed, so a crash never corrupts the save. Migrations
  are functions `vN -> vN+1`, each with a fixture test.
- Persistent person identity (save version 20, ID-01): every person has one permanent id, never reused (village people below 1,000,000, settlement residents and player characters from 1,000,000, ID-D2), with a
  register of who and where they are; the 19 to 20 step is `Identity.upgrade`, run on load, deterministic, reporting ambiguity and
  refusing (leaving the file untouched) what it cannot do. See `docs/design/IDENTITY.md`.

### 3.8 Performance

- Integer-scaled viewport. Batched tile layers with chunk culling, and texture atlases from the
  source sheets.
- Generation runs off the main thread or behind a loading screen. The budget (e.g. under 1 s for a
  64x44 map on the target phone) gets set once the platform is approved.

### 3.9 Testing

- Python suite (`tests/`): assets, generators and data. It stays the reference.
- Engine suite (headless): RNG parity, generator golden seeds, save round-trip and migrations, and
  a collision map built from a known seed.
- CI (GitHub Actions, matching the owner's precedent) runs both suites and a headless desktop export
  on every PR. Android builds run only when the owner authorises it.

## 4. Deliberately left out

Gameplay systems (combat, crafting, economy, NPC AI, quests), networking, modding, procedural
interiors and dungeons. Each waits for an owner decision and gets its own architecture note when
approved.
