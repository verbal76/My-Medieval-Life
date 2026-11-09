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

## P1. Godot prototype (current work) 🔨

On branch `claude/charming-albattani-8jjfya` (draft PR #1). The owner asked for a playable prototype
before Gate A closed: Godot 4.7 in `game/`, Android APK first, then Windows and Linux, all three
released together (CLAUDE.md section 5). The detailed rules are in `docs/BUILD_DECISIONS.md`; the
owner's decisions are in `docs/DECISIONS.md`. Status is kept here in four separate lists.

### Defects (actionable bugs)

- ⬜ None open that are known. Fixed this round (local commits, not yet released): plots over houses
  b20-b22, roofs and canopies hiding quest markers, RB (Skills) missing from the gamepad list,
  windows cut off by rounded phone corners, villagers forgetting they had met the player, keepers
  saying "you attacked me" after an animal was killed, old saves missing the sage storyline.

### Approved features: done or in progress

- ✅ Village simulation, economy, manor, animals, inheritance, journal, quests and markers, talking
  and speech bubbles, trees, camera pan / recenter / map, attack mode, blood, settings, controls
- ✅ Camera dead zone; buttons sized to their words; marker over a home quest giver's door
- ✅ Building site progress bar; giving up a site returns everything
- ✅ Inventory window from Cozy Farm's art, item-category tabs plus Skills and Journal tabs, six gear
  slots (weapon, tool, body, head, amulet, ring) (owner, 2026-10-18); the new items and their
  bonuses are agent proposals awaiting approval
- ✅ Shops at counters and stalls; tavern table food (the tavern's; theft if unpaid); stealing from
  stalls, crates and barrels; pickpocketing; stolen goods marked (owner, 2026-10-18)
- ✅ Children eat 0.6 of an adult's food, weighted the same in every food reckoning; villagers hire
  the player for a day's work (harvest, logs, ore) paid from their purse; the tanner's quest teaches
  Crafting under the scroll marker (owner-approved items; numbers are agent proposals)

### Approved but not built yet (need the owner's scope before starting)

- Building rules still open: helpers who deliver materials, NPCs building by the same rules, renting
  land, workshops after houses
- Walking into buildings: the roof lifting to show the interior, or separate interior maps (asked)
- Music and sound: the volume settings exist, but no audio has been supplied

### Future ideas (not approved)

- A main storyline after the sage; lizard and spider enemies (packs not uploaded yet); livelier
  village-log wording; marriage, births, aging and migration (living-world phase 5)

### Only testable on real devices

- Two-finger pan and pinch on a phone, Android Back, the safe-area insets on a notched or rounded
  phone, a real gamepad (right stick, LB/RB), the feel of the camera dead zone, performance on a
  mid-range phone, the Windows build on Windows

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
approves (U6–U21).

Candidate M3, needing owner approval of its mechanics: the economy vertical slice in
`docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` §14 (its Phases A + B), preceded by a world-state save
design. See `docs/LIVING_WORLD_ALIGNMENT.md` §6.

## Known limitations carried forward

- Rivers cannot meet the sea: the tileset has no river-to-sand transition tiles.
- Some animation layouts are flagged `uncertain` in the data; the owner may want to check the
  previews.
- The Mining Shaft building only partly matches its guide picture; 73 building sprites have no
  name in the guide.
- Puny Characters (TDSM) animations are not yet exported as JSON; the character generator renders
  sheets only. This is needed by step 5 if the Puny style is chosen.
