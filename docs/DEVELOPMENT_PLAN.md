# My Medieval Life: development plan

This is also the shared task board (CLAUDE.md, section 10). Claim an item by putting your branch
name next to it before starting.

Legend: ✅ done · 🔒 waiting on owner · ⬜ ready once its gate opens

## M0. Asset preparation ✅

On branch `claude/charming-albattani-8jjfya` (draft PR #1).

- ✅ Asset inventory, byte-identical dedupe, licence labels (`ASSET_MANIFEST.md`)
- ✅ Puny World generator: terrain, rivers, roads, bridges, sites (`tools/puny_world_terrain.py`)
- ✅ Miniworld animation metadata, 44 sheets (`data/miniworld_animations.json`)
- ✅ Miniworld building atlas, 28 named buildings (`data/miniworld_buildings.json`)
- ✅ Project rules, design draft, architecture proposal (this phase)
- ✅ 28 automated tests

## R0. Morris world research ✅

On branch `claude/charming-albattani-8jjfya` (draft PR #1).

- ✅ Novel corpus with stable paragraph ids; Gutenberg material excluded (`research/corpus/novel.json`)
- ✅ All 119 chapters read in context and extracted; every quote verified by script
- ✅ Merged registries with stable ids, identity decisions, checks (`research/registries/`)
- ✅ Deliverables A–J and the magic register (`docs/world/`)
- 🔒 Owner decisions in `docs/world/J_OPEN_DECISIONS.md` (era, starting county, scale, magic)
- ⬜ Optional second pass over uncited paragraphs for material culture (J Part 3)

## Gate A: owner decisions 🔒

Nothing below starts until the owner answers the essential questions in `docs/GAME_DESIGN.md`:

- U1, the primary platform
- U2, the engine
- U3–U5, the player, the core loop and the world structure (U3 answered in outline by the world
  directive: an ordinary inhabitant, not the chosen one)
- J-D1 and J-D2, the era and the starting county (`docs/world/J_OPEN_DECISIONS.md`)

The answers go into `docs/DECISIONS.md`.

## M1. Foundation (first playable, part 1) ⬜

Each step can be tested independently and is merged separately.

1. **Engine project skeleton.** Empty project under `game/` with pixel-art settings, a headless test
   runner, and a CI job that runs the Python and engine tests and exports a desktop build.
   *Test:* CI green; an exported build launches to a blank scene.
2. **Deterministic RNG and generator v2.** Implement PCG32 in Python and in the engine, and move the
   Python generator onto it (generator v2). *Test:* the same seeds produce identical number
   sequences in both; Python golden maps are regenerated and pinned.
3. **World model and tile rendering.** Import the Puny World tileset, then load a world generated
   by the Python tool (exported as JSON) and render its Ground, Trees and Bridges layers.
   *Test:* a screenshot of seed 1 matches the Python render pixel for pixel.
4. **Generator port.** Port terrain, rivers, roads and bridges to `core/`. *Test:* golden seeds are
   byte-identical with Python. If U5 says worlds are pre-built, skip this step and keep step 3's
   loader.

## M2. First playable (part 2) ⬜

5. **Character and animation.** One controllable character, using the Puny Characters sheet or a
   Miniworld unit (U13), with walk and idle in every direction. *Test:* the animation data loads,
   and a scripted direction sweep produces the expected frames.
6. **Input and camera.** Keyboard and touch movement; the camera follows, is clamped to the map and
   uses integer scaling. *Test:* a headless movement script ends at the expected cell.
7. **Collision.** A walkability grid from tile categories; water, trees and buildings block, while
   bridges and roads don't. *Test:* the collision grid for seed 1 matches a pinned fixture, and the
   player cannot enter water.
8. **Buildings.** Place a few buildings at generated settlement sites with correct footprints.
   *Test:* footprints are solid and no building overlaps a road or water.
9. **Save/load v1.** Seed, generator version and player state, written atomically. *Test:* a
   save–quit–load round trip restores the same world and position; a corrupt file is refused
   cleanly.
10. **Build for the approved primary platform.** Release build of the slice. Owner authorisation is
    needed before any distribution.

**First playable = M1 + M2.** The player walks around one generated, saved and reloaded world,
with correct animation and collision. It has no gameplay mechanics beyond movement until the owner
approves them.

## M3 and later 🔒

Defined only after Gate A, from the owner's answers on the core loop (U4) and the systems the owner
approves (U6–U19).

## Known limitations carried forward

- Rivers cannot meet the sea: the tileset has no river-to-sand transition tiles.
- Some animation layouts are flagged `uncertain` in the data; the owner may want to check the
  previews.
- The Mining Shaft building only partly matches its guide picture; 73 building sprites have no
  name in the guide.
- Puny Characters (TDSM) animations are not yet exported as JSON; the character generator renders
  sheets only. This is needed by step 5 if the Puny style is chosen.
