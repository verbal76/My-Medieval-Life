# Build 18: Phase A inventory (2026-10-22)

Read-only inventory for the Build 18 master integration directive
(`docs/directives/2026-10-22_build18_master_integration.md`, B18-DIR) and the owner's character and armour correction
(`docs/directives/2026-10-22_character_creation_armor_correction.md`). Inspected on Build 17's frozen tree (`dfec7ec`,
game code `cd7439c`); nothing in Build 17 was changed. Contact sheets were rendered and looked at.

## 1. Character creator (CC-01)

- **What it is:** `tools/puny_chargen.py`, a headless Python port of the Top-Down Sprite Maker style in
  `PUNY_CHARACTERS_v2.1_tdsm-2026.zip` (Shade, paid, credited). It composes layer sheets and recolours them with palette ramps.
  `Character-Customizer.zip` holds only layered .xcf and .psd files (registry: reference, not scriptable).
- **Output:** one 928 x 256 PNG per character: 29 frames x 8 directions (S, SE, E, NE, N, NW, W, SW), 32 px cells.
  Animations: idle, walk, sword, bow, stave, throw, hurt, death, carry, jump.
- **Layers, in draw order:** race, shoes, clothes, gloves, jaw, hair, facial-hair, eyes, eyelashes, headwear,
  ears-&-horns, weapon-overlay.
- **Options, from the pack's CSV files:**
  - race: human, cyclops, skeleton;
  - hair: 13 styles (f1-f4, m1-m9; the pack does not tie them to a sex) or none, in 11 hair colours;
  - facial hair: beard1, beard2, mustache;
  - eyes: 14 colours;
  - eyelashes: 8;
  - jaw: 1;
  - ears and horns: 11, all fantasy;
  - skin: 11 swatches (the game uses the 7 natural ones);
  - clothes: basic (7 colours), tunic (5), metal-armour (4 metals), musketeer, ninja, traveller, ronin, yabusame, samurai;
  - shoes: leather boots (3 leathers), metal boots (4 metals);
  - gloves: leather, metal;
  - headwear: 35, namely 13 European metal helms, 6 Japanese and 3 Mongol helms or hats, 5 mage hats, 3 bandanas, and civilian
    hats (villager and traveller straw hats, ranger, hunter and archer hats, rogue hood).
- **In the game today:**
  - `tools/import_game_assets.py` bakes fixed recipes into whole sheets (`game/assets/characters/*.png`, provenance recorded).
  - Character creation (`GameUI.show_creation`) offers **8 looks per sex**: 4 faces, each in basic clothes or a tunic, with
    leather boots (`game/data/appearances.json`). Every one is civilian.
  - The player keeps a sprite path (`PlayerState.sprite`, saved). The default `player_00` (ninja clothes, metal gloves) is
    used only when no creation spec is given.
- **Gap:** the game has no runtime composition. A look, a haircut or an armour piece can only change the sprite by
  swapping in a whole pre-baked sheet.
  - Required adaptation: draw the character from its recipe at run time (layer sheets plus palette ramps), save the
    recipe, and migrate saves that hold only a sprite path.
  - This is the same composition `puny_chargen.render` does; it is ported, not a second generator.

## 2. Armour (ARMOR-01)

- **Armour that shows on the body exists only as Puny Characters layers:**
  - metal-armour clothes in 4 metal colours;
  - 13 European metal helms (dark knight, dragon knight, grunt, knight, novice, paladin, scout, soldier, warrior,
    spectacled, valkyrie, jarl), plus 6 Japanese and 3 Mongol helms;
  - metal and leather boots;
  - metal and leather gloves.

  These match all 8 directions and all 29 frames. There is **no leather body armour layer and no leather cap layer**.
- **Icon sheets (inventory art only, nothing drawn on the body):**
  - `16x16 Armour RPG Icons.zip` (Shade, paid): boots, breastplates, headgear and trousers sheets.
    - 30 columns by 16, 38, 48 and 24 rows: hundreds of unnamed variants in colour bands.
    - No names, no metadata, no statistics.
  - `16x16 Survival RPG Icons.zip`, `Armour/`: 178 named icons (Leather Boots, Cap, Gloves, Jacket, Pants x19;
    Metal Chestplate, Gauntlets, Helm, Platelegs, Sabatons, Shield x12; Wooden Shield x11).
    - The game already uses 5 of them.
- **No asset carries gameplay statistics.** The existing values are agent proposals from Builds 8 and 13, marked
  provisional:

  | Item | Slot | Armour | Durability | Value | Recipe |
  |---|---|---|---|---|---|
  | `plain_clothes` | body | 0 | 240 | 2 | none |
  | `leather_armor` | body | 3 | 300 | 30 | 4 leather, workbench, Crafting 2 |
  | `iron_armor` | body | 6 | 600 | 80 | 5 iron bars + 2 leather, anvil, Smithing 3 |
  | `leather_cap` | head | 1 | 240 | 14 | 2 leather, workbench, Crafting 1 |
  | `iron_helmet` | head | 2 | 480 | 36 | 2 iron bars + 1 leather, anvil, Smithing 2 |
- **Mechanics already in place, reusable as they are:**
  - slots weapon, tool, armor (body), head, amulet, ring;
  - `PlayerState.defense()` sums body and head armour;
  - a blow is reduced by armour x 0.5 (`World` damage);
  - wear of 1 point a day worn plus 2 a blow (DVW-B4);
  - guards start in leather armour and rebuy it when it wears out.
- **The armourer:**
  - The smith keeps the armoury counter (`Counters.KEEPERS`; ARM-01, CTR-01..03) and forges iron armour and helmets.
  - Leather armour and caps are made by anyone at a workbench.
  - Stock is real goods, sold by the ordinary shop rules (SHOP-01).
- **Not present:** rarity, weight, movement effects. Each would be a new mechanic needing owner approval.

## 3. Barber (BARBER-01)

- No barber profession, building or service exists.
- The nearest service pattern is the tavernkeeper serving at a counter (CTR-02).
- The hair options available are those in section 1.

## 4. Doorways (VIS-DOOR-01)

- Door tiles (`tools/build_village.py` `DOORS`) are walkable cells. An object top over a doorway goes to the `above`
  layer, drawn over characters (`put_top`), so a character crossing the threshold is drawn under the door's upper half:
  the reported "walking under the closed door".
- No door-open state, dark-opening tile or threshold fade exists. `RoofFade` handles only roofs and the player.

## 5. Status indicators (UI-PROGRESS-01, UI-HUNGER-01, UI-HUD-01)

- **Action bar:** `GameUI.action_bar`, a `ProgressBar` with the default theme (the pale bar), centred above the player.
  Building-site bars in `main.gd` already have their own dark track and green fill.
- **Hunger icon:** the `bread` item icon, which is Cozy Farm's butter block used as a placeholder loaf
  (`import_game_assets.py`). Survival RPG Icons `Food/` has Chicken-01..07 drumsticks at the same 16 px.
- **HUD panel (owner photo 2026-10-22):** the panel is as wide as its bottom row: coins at font 18 plus the date and time,
  "Spring, Year 1 Day 2 03:59", at font 18. The bars are only 156 px wide, so the brown box covers far more of the screen
  than the bars need.

## 6. Wiki (UI-WIKI-01)

- `wiki_window.gd` sits in a tab of the Settings window (hence the SETTINGS heading).
- It has a search box, a home page of category and guide buttons, page buttons and a Back step.
- Content comes from `wiki*.gd` providers built from game data and is checked by `wiki_test.gd`. The content stays; only
  the window changes.

## 7. Wheat (VIS-CROP-01)

- Every field, the manor's and households' alike (`World._field_tiles`, `FarmPlots.tile_for`), draws one of three Puny
  World 4 x 4 edge sets: tilled 3515, growing 1747, ripe 2627.
- Rendered in the atlas, they show dirt, then green-yellow, then gold. No set shows grain heads or stubble.
- There is no harvested state: a cut field returns to tilled.
- Cozy Farm's `farming/crops*.png` sheets hold per-crop growth stages that could serve.
- Which tile the owner saw needs a look in the game: `main.gd --shot-field-state` exists for this.

## 8. Animals (VIS-ANIMAL-01)

- Cozy Farm sheets are 4 x 5 grids with no padding: pig 20 px frames, sheep 17, chicken 16.
- Each animal's top touches its cell's top edge, and the row above ends at the shared edge.
- `AnimalSprite` uses `hframes`/`vframes`, scales babies to 0.5, and the camera zoom is not always an integer. Sampling
  across a cell edge is the likely source of the stray lines, but it is not yet confirmed in the game.
- Every Cozy Farm species (cow, pig, sheep, chicken, rabbit) shares the path.

## 9. FARM-CROP-01

- `wip/farm-cropshare` `132960a` descends from `cd7439c`; it is not merged anywhere.
- Build 17's later commits (`dfec7ec`) are wiki text and documents, so a merge onto Build 18's branch needs only focused
  checks: `crop_share_test` and the farming and conservation suites the change touches.
