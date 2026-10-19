# Asset scaling standard

The world is a 16 px tile grid, drawn with nearest-neighbour filtering at integer camera zoom (CLAUDE.md
section 8). This standard says how art of any source size becomes game art that sits in that world
consistently. `tools/assets/sheets.py` does the measuring and scaling; `tools/import_game_assets.py` applies
it, with each step recorded in `game/assets/PROVENANCE.json`.

## 1. The rule: one pixel density

**Every sprite is drawn at the world's density: one art pixel is one world pixel, and a tile is 16 of them.**
- A sprite's canvas size does not matter; what it shows does.
- Art drawn at that density is used 1:1, whatever its canvas: 32 px frames, 32 px tiles covering 2 × 2 world tiles, a 92 px tree.
- Art drawn bigger (a 96 px cell holding an 80 px horse) is reduced to the target size below.
- Art is never mixed at two densities inside one object.

| Source density | Treatment | Packs |
|---|---|---|
| 16 px world tiles, or sprites drawn to match | 1:1 | Puny World, Puny Characters, Puny Monsters, Puny Dungeon, Cozy Farm, miniworld, Survival icons, MiniFolks (32 px frames, small animals inside), Craftpix plants and crops, Forgotten Memories (32 px tiles = 2 × 2 world tiles), Living Forest trees |
| Drawn about 2× or 3× larger | Reduce by an integer reciprocal (1/2, 1/3) with `sheets.scale(..., method="box")`: area averaging, then alpha cut at 128 so edges stay hard | Animal Farm (96 px cells): 1/3. Skeletons (96 × 64 frames, 48 px figure): 1/3 |
| Drawn at half density (8 px grid) | Not used: upscaling would double the pixels and clash | Tiny Ranch |

Use integer factors only (2×, 1/2, 1/3), never 0.4 or 1.5: non-integer factors smear pixel art. If no integer factor gives a size within the table below, pick the nearest and record it in the pack's `scale` field in `docs/assets/packs.json`.

## 2. Target sizes: visible content, in world pixels

These are measured from the art in the game now (`sheets.py grid` and content bounds), so new art matches it.

| Thing | Width × height (px) | Measured from |
|---|---|---|
| Adult human | 14 × 16 | Puny Characters (32 px frame) |
| Child | about 3/4 of an adult | drawn at scale |
| Chicken, bird | 13 × 12; 8 × 7 | Cozy chicken; MiniFolks bird |
| Rabbit, fox | about 12 × 10; 16 × 11 | Cozy rabbit; MiniFolks fox |
| Sheep, pig | 14 × 14; 16 × 18 | Cozy Farm |
| Deer (doe, stag), wolf | 14 × 14, 15 × 17; 17 × 11 | MiniFolks |
| Cow, bear | 24 × 16; 22 × 11 | Cozy cow; MiniFolks bear |
| Horse | about 27 × 22 (taller and longer than a cow; head above a person's) | target for Animal Farm at 1/3 |
| Skeleton (enemy) | 16 tall, a person's height | target for the free skeletons at 1/3 |
| Crop in a field cell | within 16 × 16; may reach up to 8 px above its cell | Cozy crops; Craftpix crops (1:1) |
| Bush, flower | within 16 × 16 | Puny World |
| Young tree; orchard tree; mature forest tree | 22 × 20; up to about 48 × 48; 55 × 92 (oak), 23 × 84 (pine) | Living Forest; Craftpix fruit trees (1:1) |
| Handcart, crate, barrel | 16 to 24 wide (1 to 1.5 tiles) | Puny World mine cart (16) |
| Crafting station | 16 to 32 wide (1 to 2 tiles) | Puny World anvils, benches |
| Door; house | 16 wide; 7 to 10 tiles wide | Puny World buildings |

## 3. Placement: origin, ground contact, sorting, collision

**Origin**
- An actor's or object's position is its feet: the ground point.
- A sprite is offset so the bottom of its visible content sits on that point, not the bottom of its canvas.
- Animal sheets use `offset = (0, -frame/2 + 3)` because the art's feet are about 3 px above the frame bottom.
- A new sheet whose feet sit elsewhere gets its own offset, measured with `sheets.content_box`.

**Ground contact**
- Shadows, if the art has them, sit on the ground point.
- Nothing floats: check a screenshot.

**Sorting**
- Actors, carts and animals are children of the y-sorted `actors` node, so whatever stands lower on screen draws in front.
- Tall static art (trees, buildings) draws its top in the overlay layer (`above`) so actors walk behind it.

**Collision**
- Collision is per cell (`VillageMap.is_solid`).
- A static object is solid on the cells of its base only: a tree's trunk cell, a crate's cell, a counter's two cells. Its canopy or top is never solid.
- Moving actors are not solid to each other.

**Navigation**
- An object never closes the only path through a gap (a door, the space between two trees).
- `tree_test` and `play_test` check paths; new placement code should use the same placement checks as storefronts (`Business.front_place`): open cells, no road, no plant, tree or interior.

**Interaction range**
- Things are used from the cell in front of them (`use` cells), within about 1.3 tiles of the player's feet.

**Animation**
- Frames come from the sheet's measured grid (`sheets.detect_grid`, or `common_strip_width` for a pack of one-row strips).
- Row meanings come from the pack's own notes. Where the notes are silent, mark the row **uncertain** in `docs/BUILD_DECISIONS.md` (CLAUDE.md section 4) and look at it.
- Frame duration: 0.15 to 0.2 s for walks, matching the existing sheets.

## 4. Checks every integration passes

1. **Look at it:** a screenshot (headless with a virtual display, as in `scratchpad` shot scripts), checking scale against a person standing beside it, feet on the ground, and sorting when walked around.
2. **Validate:** `python3 tools/assets/check_assets.py`. It catches files not imported through the pipeline, broken `res://` paths, and animation rows beyond the sheet.
3. **Re-scan:** `python3 tools/assets/scan_packs.py`, so the registry records the import.
4. **Test:** a gameplay test for the system the art serves; art that is only shown is not counted as integrated.
5. **Record what was not checked:** real devices (phone memory, frame rate) unless tested there.
