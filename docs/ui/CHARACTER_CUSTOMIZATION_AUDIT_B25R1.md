# Character customisation audit (B25R1-007) and the creator, origin and modal polish (B25R1-008)

Owner directive 2026-11-03, `docs/directives/2026-11-03_b25r1_master_directive.md` (branch `wip/requirements-control`),
sections 6 and 7 (7A, 7B, 7D), validation scenarios H and I. Branch `wip/b25r1-ui`, based on `wip/expansion20` at `a459186`.

## 1. Audit: what limited the options (before this change)

The character is drawn at run time by `CharacterLook` (`game/scripts/view/character_look.gd`) from a recipe
`{"picks": {layer: option}, "swatches": {colour selection: ramp row}}`: the PUNY CHARACTERS (TDSM) layer sheets stacked in
the pack's draw order, each recoloured by palette ramps (`ramps_replace`: every reference colour of the ramp's first row is
replaced by the chosen row's colour at the same place). The rules, ramps and choice lists are written by
`tools/import_game_assets.py` into `game/data/character_style.json` (generated; never hand-edited).

| Possible limit | Finding |
|---|---|
| Hardcoded option limits | **The limit.** `tools/import_game_assets.py` `CREATION_PICKS` / `CREATION_SWATCHES` (CC-01, owner 2026-10-22: "an ordinary medieval civilian") offered: race `human` only; no `ears-&-horns`, no `jaw`; skin rows 0-6 of 11; hair rows 0-4 of 11; eyes 11 of 14 rows (no red 10-11, no blank white 13). Every hair style (13), beard (3), eyelash (8), plain clothes and tunic in every dye, and leather boots were already offered. |
| UI controls | The creator (`GameUI.show_creation`) built one row per entry of `CREATION_FEATURES` from those lists; nothing else gated it. Colours could only be stepped one at a time with `<` and `>`. |
| Gender gating | **None in the UI**: every hair style (the pack's `f*` and `m*`), beard and eyelash was offered to a man and a woman alike. Only `CharacterLook.random_recipe` gave a woman no beard (still so for "Plain villager"; "Randomize" now rolls a beard for anyone). |
| Palette restrictions | The pack's ramps have 11 skin rows (7 natural; lavender, green, yellow-green, red), 11 hair rows (5 natural; lemon, red, green, cyan, blue, magenta), 14 eye rows, 7 cloth dyes, 5 tunic dyes, 3 leathers, 2 skeleton rows. No blue or grey skin, no natural blonde or copper hair, no violet or amber eyes, no brown, black or white cloth. |
| Sprite layers | The TDSM zip draws more than creation offered: race `cyclops` (skin-recoloured, its own single eye) and `skeleton` (its own `skeleton` ramp: bone and eye glow); `ears-&-horns` (elven ears in skin colour; cat, rabbit and goat ears and horns, antlers, unicorn horn, bone horns); `jaw` (a jutting jaw in skin colour); headwear (35), gloves (2), metal boots and gear clothes. The ears, jaw, cyclops and skeleton sheets were not imported into `game/assets` at all. |
| Rendering architecture | Supports everything: any layer, any ramp row; a recipe's sheet is composed once and cached. `human_only`: eyes and eyelashes are drawn only on a human (a cyclops and a skeleton carry their own eyes in the body sheet). Rows beyond a ramp's end are clamped. Free (unlimited) colour would need ramps computed per recipe and a colour stored in the save: not done (see section 4); instead the ramps gained named rows, which the renderer already recolours with. |
| Animation support | Every layer sheet has all 29 frames x 8 directions; checked frame by frame for every option on every body (`char_create_test`). |
| Save data | `PlayerState.appearance` / `heir_appearance` keep the recipe as a dictionary; `CharacterLook.normalize` gives any layer the recipe lacks the value "none". New layers are optional keys: **no save format change** (save version stays 23). |
| Equipment | Headwear, armour (metal and the gear catalogue's clothes), gloves and metal boots are drawn by worn items (`worn_layers`, ARMOR-01). They stay out of creation: "Character creation must not grant equipment" (directive section 6). |

## 2. What changed (B25R1-007)

- `tools/import_game_assets.py`: `CREATION_PICKS` adds `race` cyclops and skeleton, all 11 `ears-&-horns` and the `jaw`;
  the creator offers **every row of every ramp** (`creation_swatches`). `EXTRA_RAMP_ROWS` adds named rows after the pack's
  own (GAME EXPANSION, generated: each shade of a pack row keeps its place and lightness with a new hue and saturation, so
  the shading is the pack's), so saved row numbers keep their colours: skin +10 (sky blue, deep blue, stone grey, ash,
  charcoal, teal, rose, moss, frost white, ochre: 21 in all), hair +11 (flaxen, copper, chestnut, strawberry, raven blue,
  violet, rose pink, teal, orange, silver blue, forest: 22), eyes +8 (violet, pink, amber, ice blue, grey, hazel, orange,
  light green: 22), cloth +8 (brown, black, cream, purple, navy, forest green, ochre, white: 15), skeleton +3 (blue, green and
  gold glow: 5). `character_style.json` gains `added_rows` (their names). The 14 new layer sheets are copied unchanged from
  the zip with provenance (`game/assets/PROVENANCE.json`). The Build 7-17 looks (`appearances.json`) are unchanged.
- `CharacterLook`: `random_recipe(rng, sex, wild := false)`: the default is still an ordinary villager (`NATURAL`,
  `NATURAL_ROWS`: CC-01's limits, so every random look the game draws for itself and every seed's look are unchanged);
  `wild` rolls anything. `swatch_name` names every row; `swatch_accent` tells skeleton rows apart by their eye glow.
- The barber (BARBER-18) offers the same hair styles and now every hair colour, as it reads the creator's lists.
- Continuity (DCR-01): an **intentional revision** of CC-01's "natural skin, hair and eyes; human only; no horns or ears",
  ordered by the owner ("Unlock all cosmetic character customization options. If a player wants to create a green elf, that
  is acceptable"); CC-01's "appearance only; same kit and coins; no headwear, armour or gloves" is kept.

## 3. The interface (B25R1-008)

- `game/scripts/ui/ui_style.gd` (`UIStyle`): the shared look, for the region map's worker to adopt too. Pixel-art nine-slice
  boxes generated in code (no art file): `frame` (outline, bronze rim lit from the top left, gold rivets in the corners, dark
  wood), `inset` (a sunken box), `parchment` (a page); buttons with normal, hover, pressed (sunk one pixel), disabled,
  `selected` (gold edge) and `primary` (gold) looks; a gold focus ring for pad and keyboard; `theme(px)` styles every Button,
  LineEdit and Label under a node; `label(text, kind)` for the type scale (title 24, head 17, body 16, small 13); `Swatch`, a
  colour button with a gold ring when chosen. `px` is the art pixel: 2 interface units on a desktop, 1 in the phone layout.
- `game/scripts/ui/look_preview.gd` (`LookPreview`): an animated sheet preview (walking, standing, sword swing, carrying;
  eight directions, turning by itself until turned), drawn at a whole-number scale on a shadow (`LookPreview.Stage`).
- Character creation (`GameUI.show_creation`): a centred card (at most 980 x 572 on a desktop, the whole safe area of a
  phone), "Who are you?" and the large preview with Turn, Pose, Randomize and Plain villager on the left; the name fields,
  four pages (Body, Hair, Face, Clothes) of `< option >` rows and colour swatch grids, the note and Back / Begin on the
  right. Rows that do not apply are left out (a skeleton chooses bone, not skin; a cyclops and a skeleton no eye colour or
  eyelashes; no boots, no boot colour; a tunic its own dyes).
- The origin (`GameUI.show_origin`): a centred card, the character standing framed with its name and the gold Begin on the
  left, the story on a parchment page on the right (reading width about 600 units). Its words are unchanged (`ORIGIN_STORY`).
- Modal behaviour (7D): `GameUI.dimmer`, a full-screen layer between the HUD and the windows, shows whenever a window is
  open: it dims the HUD and the world and takes every touch or click outside the window, so no HUD button under it can be
  pressed. The title, creation, origin, death and demo-ended screens hide the HUD altogether (`MODAL_NO_HUD`). Pause
  behaviour is as before (`_open`'s `pause`). The region map panel is untouched (another worker's).

## 4. Not done, and why

- Free colour choice (any RGB): it would need a ramp built per recipe and the colour itself in the save; the wide named
  palettes (21-22 colours per selection) give broad freedom through the existing recolouring without a save change.
- Headwear, gloves, metal boots and gear clothes stay equipment (directive section 6).
- Saves made with the new options and opened in an older build would draw a cyclops or skeleton's body as missing (an
  older build has no such layer); saves are not meant to go back to older builds, and old saves load in this one unchanged.
- Real-device checks (an Android phone, a gamepad) are still to do; the phone layout was checked in a 2400 x 1080 window.
