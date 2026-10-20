# Sprite needs: missing and weak sprites (B14-12)

Owner request, 2026-10-19 (register entry B14-12): a list of the sprites the game needs but lacks, and the weak
ones, with pixel-grid copies to draw or improve in Aseprite.

**Missing** means the game draws something with a placeholder: a coloured rectangle, a shape drawn in code, or a
tile or icon borrowed from something else. **Weak** means art exists but falls short: it is too small or
mis-scaled, a recolour stands in, there is one frame where animation is expected, or one icon serves two items.

**How the list was made.** Every entry was found in the code, the import provenance or the project's own
notes, not guessed:
- the code: `game/scripts`, searched for `draw_rect`, `ColorRect`, code-drawn shapes, scale factors, the fallbacks
  in `ActorSprite`, `AnimalSprite` and `_tile_texture`, and the item-icon lookups;
- the import record: `game/assets/PROVENANCE.json`, which says which source picture each icon was cut from
  (`tools/import_game_assets.py`);
- byte-identical files (sha256) in `game/assets/icons` and `game/assets/ui`;
- the station tiles in `tools/build_village.py`, `game/scripts/core/fitting.gd` and `business.gd`;
- the open art items in `docs/release/BUILD_13_MID_DEVELOPMENT_AUDIT.md`, `BUILD_14_OPEN_ITEMS_AUDIT.md`,
  `docs/BUILD_DECISIONS.md` and `docs/assets/packs.json`.

Every item in `game/data/items.json` has an icon file, so nothing in the inventory is drawn blank. The item entries
below are items whose icon is another object's picture, a recolour, or shared with another item.

**Sizes** follow `docs/assets/ASSET_SCALING_STANDARD.md`:
- one art pixel is one world pixel, and a world tile is 16 px;
- an adult is 14 × 16 px visible, in 32 px frames;
- item icons are 16 × 16 px;
- a crafting station is 16 to 32 px wide;
- a handcart is 16 to 24 px wide.

Within each group, entries are ordered by how often a player sees the sprite in play.

## The package

`python3 tools/assets/sprite_package.py` builds the package under `out/` (git-ignored, CLAUDE.md section 3) and
zips it as `out/sprite_package.zip`, together with a copy of this file. Each entry gets two files in
`out/sprite_package/`:

| File | What it is |
|---|---|
| `<category>__<id>.png` | The grid copy. On the left, under "now": the current art enlarged, with a 1 px grid between source pixels and a gold line round each frame, labelled column,row (`tools/assets/sheets.py contact`). On the right, under "draw here": an empty grid canvas of the size the game needs. Entries with no art have only the canvas. |
| `<category>__<id>_1x.png` | The file to edit in Aseprite, at the game's real size. It is the needed canvas with the current art in its first frame, or empty when nothing exists. For baby animals and children, it is the adult sheet, to draw the young one over the same frame grid. |

Art drawn into a `_1x` file enters the game only through `tools/import_game_assets.py`, which records its
provenance. Nothing in this package changes the game.

## Characters (3)

| # | id | What it is | Where the game uses it | Drawn with now | Why it is missing or weak | Size needed | Frames and directions |
|---|---|---|---|---|---|---|---|
| 1 | `tool_swing` | A person swinging a pickaxe, axe or hammer | `actor_sprite.gd` `ANIMS.swing` and `hold()`; mining, woodcutting and smithing by the player and villagers (`main.gd`, NPC work) | The bare-handed throw frames (sheet columns 16-18), with the tool's 16 px item icon laid over the hand, scaled 0.85 and turned per frame (`SWING_ANGLES`) | **Missing.** The Puny Characters sheet has no tool animation (B8-007, "Real swing art: art needed"). A 0.85 scale is not an integer, so the icon loses pixels. The tool floats over the hand. | 32 × 32 frames, figure 14 × 16 like the rest of the sheet | 3 frames × 8 directions (rows S, SE, E, NE, N, NW, W, SW): 96 × 256. One set per tool (pickaxe, axe, hammer), or a tool-less hand pose plus a separate tool layer |
| 2 | `child` | Children and adolescents | `main.gd` `_sync_sprites`: `Life.npc_scale` (`balance.json` life `child_scale` 0.5, `adolescent_scale` 0.75) | The adult sheet at half size (children) or three-quarter size (adolescents) | **Weak.** Halving a 32 px sheet drops every second pixel. 0.75 is not an integer factor and smears the art (scaling standard section 1). The standard asks for a child about 3/4 of an adult, drawn at the world's density. | 32 × 32 frames; child figure about 11 × 12 visible, adolescent about 13 × 14 | The full sheet layout: 29 columns × 8 directions (928 × 256), as `ActorSprite.ANIMS` reads it. At minimum idle, walk, hurt and death (columns 0-4, 19-24) |
| 3 | `sit` | Sitting on a chair or stool | `actor_sprite.gd` `sit()`; villagers at tavern tables and home tables (`main.gd` `_show_sitter`) | The standing idle frame, cut off at the knees by a shader (`SIT_CUT`) | **Missing.** The sheet has no sitting frames (PL1-07 / PL2-013, "Sit art: art needed"). | 32 × 32 frames | 1 frame × 4 directions (S, E, N, W): 128 × 32. A 2-frame idle is optional |

## Animals: baby sheets (10)

A young animal of a species with no `<skin>_baby.png` is drawn with the adult sheet at half size
(`animal_sprite.gd` `show_state`; `animal.gd` `baby_skin()`; `balance.json` animals note: "half scale of the adult
sheet where there is none").
- **Weak:** halving drops every second pixel. The bird's 8 × 7 body becomes 4 px.
- **Who has babies:** the Cozy Farm livestock (cow, pig, sheep, chicken) and the Cozy rabbits. All wild species
  also breed (wildlife refuges, WR-01), so their young appear in the woods.
- **What to draw:** a baby sheet with the same layout and frame size as the adult, so the same `ROWS` table
  reads it.
- **The `_1x` file** is the adult sheet, to draw the young animal smaller in each frame.

| # | id | Species (wood) | Adult sheet and layout | Needed sheet | Frames used (`AnimalSprite`) |
|---|---|---|---|---|---|
| 4 | `mini_bunny_baby` | Rabbit (MiniFolks skin) | `animals/mini_bunny.png`, MiniFolks 32 px | 128 × 128 | idle 4, walk 4, hit 2, death 3 (rows 0-3) |
| 5 | `boar_baby` | Wild boar (Puny Monsters skin) | `animals/boar.png`, Puny 32 px, 12 × 8 | 384 × 256 | walk frames 0-3 × 8 directions |
| 6 | `boar_grey_baby` | Wild boar, grey | `animals/boar_grey.png`, Puny 32 px | 384 × 256 | as the boar |
| 7 | `mini_boar_baby` | Wild boar (MiniFolks skin) | `animals/mini_boar.png`, MiniFolks 32 px | 160 × 192 | idle 4, walk 4, attack 5, hit 2, death 4 |
| 8 | `mini_doe_baby` | Deer, female | `animals/mini_doe.png`, MiniFolks 32 px | 160 × 192 | idle 4, walk 4, attack 5, hit 2, death 4 |
| 9 | `mini_stag_baby` | Deer, male (a fawn needs no antlers: the doe's baby could serve both) | `animals/mini_stag.png`, MiniFolks 32 px | 224 × 224 | idle 4, walk 4, attack 5, hit 2, death 4 |
| 10 | `mini_fox_baby` | Fox | `animals/mini_fox.png`, MiniFolks 32 px | 192 × 192 | idle 4, walk 4, attack 6, hit 2, death 4 |
| 11 | `mini_wolf_baby` | Wolf | `animals/mini_wolf.png`, MiniFolks 32 px | 224 × 256 | idle 4, walk 6, attack 5, hit 2, death 4 |
| 12 | `mini_bird_baby` | Bird | `animals/mini_bird.png`, MiniFolks 16 px | 64 × 48 | idle 4, flight 4, death 3 |
| 13 | `mini_bear_baby` | Bear (west wood only) | `animals/mini_bear.png`, MiniFolks 32 px | 320 × 256 | idle 4, walk 6, attack 6, hit 2, death 4 |

## Items and icons (18)

Every item icon is 16 × 16, one frame. Icons appear in:
- the inventory (`inventory_window.gd`);
- shop and stall windows, the wiki and the HUD (`game_ui.gd` `ICON`);
- loot piles on the ground (`main.gd` `_loot_icon`);
- a villager's hand while swinging (`actor_sprite.gd` `hold`).

"Source" is the picture the icon was cut from (`PROVENANCE.json`).

| # | id (item) | Drawn with now (source) | Why it is missing or weak |
|---|---|---|---|
| 14 | `bread` (Loaf of bread) | Cozy Farm `items.png` cell (2,3): **a butter block** | **Missing:** the import calls it "used as a placeholder loaf". Bread is a staple food, sold, eaten and baked every day (`knead_flatbread`, `bake_egg_bread`). |
| 15 | `pottage` | Survival icons `Metal-Pot-01`: an empty pot | **Weak:** an empty cooking pot, with no food in it. Pottage is the village's commonest cooked food (`cook_pottage`). |
| 16 | `plain_clothes` (Plain clothes, armour slot) | Cozy Farm `items.png` cell (4,5): white cloth, **byte-identical to `wool_cloth`** | **Weak:** two different items share one icon. The starting outfit looks like a bolt of cloth. |
| 17 | `handcart` | Survival icons `Wood-Plank-Slab-03`: a plank slab | **Missing:** a stand-in "until the owner's own art" (`import_game_assets.py`; B13 audit). |
| 18 | `cart_wheel` | Survival icons `Wooden-Shield-01`: **a round wooden shield** | **Missing:** a stand-in (as above). |
| 19 | `cart_axle` | Survival icons `Stick-01`: a stick | **Missing:** a stand-in (as above). |
| 20 | `cart_ironwork` | Survival icons `Metal-Slab-02`: an iron slab | **Missing:** a stand-in (as above). |
| 21 | `feather` (Feathers, from chickens and birds) | Survival icons `Leaf-05`: **a yellow leaf** | **Missing:** a leaf stands in for a feather. |
| 22 | `padlock` | Survival icons `Metal-Nugget-02`: lumps of iron | **Missing:** the import calls it "a lump of iron as the padlock". |
| 23 | `lockpick` | Survival icons `Arrow-05`: an arrow | **Missing:** "a thin iron arrow-shaft as the lockpick". |
| 24 | `plough` (Hand plough) | Survival icons `Hoe-02`: a hoe | **Missing:** "the pack has no plough, so its hoe stands in" (PL2-015). |
| 25 | `linen_bandage` | Survival icons `Silk-Fabric-04`: white silk cloth | **Weak:** a bolt of fabric, not a rolled bandage. It is close to `plain_clothes` and `wool_cloth`. |
| 26 | `herbal_poultice` | Survival icons `Leaf-11`: a green leaf | **Weak:** a bare leaf, not a prepared poultice. |
| 27 | `oak_sapling` | Living Forest `T_sapling.png`, box-filtered into 16 px | **Weak:** shrunk by a box filter, so its pixels are blurred. It comes from the same source picture as the pine sapling. |
| 28 | `pine_sapling` | Living Forest `T_sapling.png`, as the oak | **Weak:** as the oak sapling: the two kinds read alike. |
| 29 | `rotten_apple` | The apple icon tinted brown 55% | **Weak:** a recolour of the apple. |
| 30 | `rusty_sword` | Survival icons `Sword-01` (the copper sword's icon) tinted rust-brown 45% | **Weak:** a recolour of another item's icon. |
| 31 | `rusty_pickaxe` | Survival icons `Pickaxe-02` (the pickaxe's icon) tinted rust-brown 45% | **Weak:** a recolour of another item's icon. |

## Buildings and stations (10)

| # | id | What it is | Where the game uses it | Drawn with now | Why it is missing or weak | Size needed | Frames and directions |
|---|---|---|---|---|---|---|---|
| 32 | `handcart_world` | A handcart standing or pulled in the world | `main.gd` `_sync_carts` (B14-06, carts in play) | The mine cart on its rail, paid atlas tile 3009 (`CART_TILE`), one tile, flipped for left | **Missing:** "a stand-in until the owner's own art". A box on rails, seen from above. The same picture is drawn facing up, down, left and right. | 16 to 24 wide (scaling standard: handcart); canvas 24 × 24 per view | 3 views (side, facing down, facing up; the side flipped for the other side): 72 × 24. A 2-frame wheel turn is optional |
| 33 | `storefront_counter` | A household's storefront counter, and the market pitch | `business.gd` `_draw_front` and pitches, `AWNING` (layer `below0`) | Tiles 1890 (a plank table top) and 3502 (a small wooden crate) side by side | **Weak:** "the storefront counter is a weak stand-in (a stall table and crate)" (B13 audit; `packs.json` craftpix_plants). It does not read as a shop counter. | 2 tiles, 32 × 16 (a taller version would need a top layer drawn over it) | 1 frame |
| 34 | `fit_anvil` | An anvil the player places in a room they built | `fitting.gd` `ART.anvil` | Tile 2540, **a plank table top** (one of `build_village.py` `TABLE_TILES`) | **Missing:** a table stands in for the anvil. | 16 × 16 | 1 |
| 35 | `fit_forge` | A forge the player places | `fitting.gd` `ART.forge` | Tile 2567, **the oven's tile**: one quarter of the domed oven (`HEARTH_TILES`) | **Missing:** the oven's picture is reused for the forge, and only a quarter of it shows. | 16 × 16 (one cell) | 1, or 2-3 frames of glowing coals |
| 36 | `fit_shelves` | Shelves (more goods on sale) | `fitting.gd` `ART.shelves` | Tile 2542, a bare plank table top | **Missing:** a table stands in for shelves of goods. | 16 × 16 | 1 |
| 37 | `fit_counter` | A shop counter the player places | `fitting.gd` `ART.counter` | Tile 3578, one grey stone piece of the tavern's counter | **Weak:** one cell cut out of a longer counter; it reads as a block of stone. | 16 × 16 | 1 |
| 38 | `stove` | The stove in the bakehouse and the kitchen | `build_village.py` `WORKSHOPS` bakehouse and kitchen | Three village tiles: a coal bed and a pot, in an L shape (PL1-13) | **Weak:** "Recognisable stove: hearth with pot; chimney art" (B14 audit). | 32 × 32 (2 × 2 cells) | 1, or a few frames of fire |
| 39 | `sawhorse` | Where planks are sawn | `build_village.py` `WORKSHOPS.carpentry` and the sawmill (PL2-010) | Two village tiles: logs on a trestle bench | **Weak:** "Sawhorse look: trestle bench; saw art" (B14 audit). There is no saw. | 32 × 16 (2 cells) | 1 |
| 40 | `apothecary_station` | The apothecary's working place | `build_village.py` `WORKSHOPS.apothecary` | **The stove's tiles** (coal bed and pot) | **Weak:** the cooking stove stands in. The apothecary has no station of its own, such as a mortar or a still. | 32 × 32 | 1 |
| 41 | `stall_display` | The display of the larger market stall (one item on sale) | `docs/BUILD_DECISIONS.md` "Larger market stall" | Nothing ("no sprite is drawn over the stall (deferred)") | **Missing:** no art at all. | 16 × 16 over the stall | 1 |

## Terrain and props (5)

| # | id | What it is | Where the game uses it | Drawn with now | Why it is missing or weak | Size needed | Frames |
|---|---|---|---|---|---|---|---|
| 42 | `crop_carrot` | A carrot field, growing and ripe | `farming.gd` `tile_for`; `village.json` `tiles.field` | **The wheat field tiles**: growing 1747 (olive) and ripe 2627 (yellow), as 4 × 4 edge sets | **Missing:** every crop looks like wheat. Craftpix crop stages are an open opportunity (`packs.json`). | Two 4 × 4 edge sets of 16 px tiles (growing, ripe): 128 × 64. A single 16 × 16 plant per state, laid over the tilled-soil set, would also work. | 1 per state |
| 43 | `crop_potato` | A potato field | as above | the wheat tiles | as above | as above | as above |
| 44 | `crop_herb` | A herb bed (it yields wild flowers) | as above | the wheat tiles | as above | as above | as above |
| 45 | `loot_pile` | A dropped pile or a carcass's meat | `main.gd` `_sync_loot`, `_loot_icon` | The first item's 16 px icon (raw meat for a kill), or coins | **Weak:** an inventory icon stands on the ground. There is no carcass or pile picture. | 16 × 16 | 1 |
| 46 | `small_boulder` | A small boulder (stone) | `map_view.gd` `_add_small_boulder` | The boulder tile 1964 shrunk 16 → 10 px with nearest-neighbour filtering | **Weak:** a non-integer reduction, so pixels drop unevenly (scaling standard section 1). | 16 × 16 cell, boulder about 10 px, on the cell's bottom | 1 |

## Effects (2)

| # | id | What it is | Where the game uses it | Drawn with now | Why it is missing or weak | Size needed | Frames |
|---|---|---|---|---|---|---|---|
| 47 | `fireball` | The fireball spell in flight | `main.gd` `fireball()`, `_projectiles_step` | The `fireball` item icon, which is Survival icons `Magic-Staff-05`: **a magic staff** | **Missing:** a staff flies through the air as the fireball. | 16 × 16 | 4 frames of flicker: 64 × 16 |
| 48 | `target_marker` | The marker over the creature the player targets | `main.gd` `_build_scene` (`target_marker`) | The iron sword icon, turned 225° and scaled 1.5 | **Weak:** another item's icon, at a non-integer scale (1.5 doubles some pixels and not others). | 16 × 16 | 2 frames of bob or pulse: 32 × 16 |

## UI (5)

| # | id | What it is | Where the game uses it | Drawn with now | Why it is missing or weak | Size needed | Frames |
|---|---|---|---|---|---|---|---|
| 49 | `equipment_slots` | The empty-slot glyphs (weapon, tool, armour, head, amulet, ring) in the inventory | `inventory_window.gd` (`slot_%s.png` in a 14 px square) | 128 px flat vector glyphs, shrunk to 14 px. **`slot_weapon` is byte-identical to `attack`, `slot_tool` to `skill_woodcutting`** | **Weak:** shrinking 128 → 14 px is not an integer factor, so the result is soft beside the 16 px pixel-art icons. Two glyphs are shared with other buttons. The "now" copy approximates the shrink with nearest-neighbour filtering. | 14 × 14 each, in an 18 px cell | 6 glyphs: 84 × 14 |
| 50 | `skill_trading` | The Trading skill's glyph | `game_ui.gd` skills page (`_ui_icon("skill_" + k, 28)`) | **Byte-identical to the coins glyph** (`ui/coins.png`, beside the purse) | **Weak:** one glyph means two things. | The file is 128 × 128, drawn at 28 px, like the other flat glyphs | 1 |
| 51 | `locked_cell` | The padlock over a locked bag cell | `inventory_window.gd` `_draw_lock` | Code-drawn rectangles: a dark wash, a shackle, a body and a keyhole | **Missing:** a shape drawn in code. | 18 × 18 (the bag cell) | 1 |
| 52 | `house_sign` | The family-name sign by each house door | `main.gd` `_sync_signs` | A text Label on a flat brown box (StyleBoxFlat) | **Missing:** no art; a code-drawn box. The name stays text, so the sign needs a stretchable middle. | About 24 × 9 board (nine-slice), with an optional post | 1 |
| 53 | `enemy_hp_bar` | The health bar over a struck creature | `main.gd` `_hit_fx` (`HpBar`) | Two ColorRects, 16 × 2 (dark back, red fill) | **Missing:** coloured rectangles. Small and seen only in fights. | 16 × 4 (frame plus fill) | 1 frame, plus a fill strip |

## Not included, and why

- **The smithy's forge is drawn with the same domed tiles as the bakehouse oven.** Both are Shade's art, pasted
  from his own smithy and kitchen (`build_village.py` `WORKSHOPS`). Shade may have meant that dome as a
  furnace, so it is not counted as a stand-in. Only the one-tile fitted forge (#35) is listed. **Uncertain.**
- **The wheat icon** (Survival icons `Herb-Bundle-01`, a herb bundle) reads as a yellow sheaf when looked at.
  It is left out. **Uncertain:** it is named for herbs in its own pack.
- **Frame choices marked uncertain in `docs/BUILD_DECISIONS.md`** are about which frames are read, not about
  missing art, so they are not listed:
  - the Puny Monsters boar walk uses frames 0-3;
  - the MiniFolks bunny's rows 2 and 3 are read as hit and death;
  - the MiniFolks bird's rows 1 and 2 are read as flight and death, and its idle row also serves for attack
    and hit.
- **Wildlife refuges** (dens, burrows, caves) are hidden in the world. Whether they are shown is an open owner
  question (`docs/BUILD_DECISIONS.md`, wildlife refuges), so no sprite is listed yet.
- **Skeletons (B14-09) and the horse (B14-11):** art exists in the stored packs (free skeletons; Animal Farm, the
  horse already imported as `animals/farm_horse.png`) and waits on its own register entries.
- **Code-drawn tools rather than sprites:**
  - the placement ghost (`placement_ghost.gd`), a tinted footprint;
  - the village map's player dot and frame (`village_map_view.gd`);
  - the speech bubble (`speech_bubble.gd`);
  - the journal's book spine (`game_ui.gd`);
  - the starting meadow backdrop (`main.gd`).
