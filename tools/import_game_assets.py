"""Copy the art the Godot game needs out of the asset archives, recording provenance.

CLAUDE.md section 3: art enters the engine project only through a documented import step that
records each file's source archive and path. This is that step. It writes:

    game/assets/tiles/punyworld-tiles.png            PUNY-WORLD-PAID_v1.zip (Tiled atlas)
    game/assets/tiles/punyworld-overworld-tiles.png  PUNY_WORLD_v1.zip (free overworld atlas)
    game/assets/characters/villager_NN.png           PUNY CHARACTERS (TDSM) generated with
    game/assets/characters/bandit_NN.png             tools/puny_chargen.py, fixed seeds
    game/assets/characters/player_NN.png
    game/assets/characters/guard_NN.png
    game/assets/icons/<item>.png                     16x16 Survival RPG Icons.zip, one icon per item
    game/assets/tiles/cozyfarm-tiles.png             CozyFarm_full_version.zip (fences, gates)
    game/assets/tiles/crops.png                      CozyFarm_full_version.zip (field plants by stage, CROP_ROWS)
    game/assets/animals/<species>.png                CozyFarm_full_version.zip (livestock, bunnies) and
                                                     PunyMonsters.zip (boars)
    game/assets/characters/player_<s><n>_<outfit>.png the Build 7-17 player looks (game/data/appearances.json,
                                                     now each with its recipe: what old saves migrate from)
    game/assets/characters/layers/<layer>/<option>.png  CC-01: the uncoloured PUNY CHARACTERS (TDSM) layer
                                                     sheets character creation offers, copied unchanged and
                                                     drawn at run time from a recipe (CharacterLook), with
    game/data/character_style.json                   the draw order, palette ramps and choice lists they use
    game/assets/fx/blood_N.png                       kenney_splatpack.zip, shrunk and tinted dark red
    game/assets/fx/campfire.png                      Animated Pixel Campfire (SMStudios)/Sprite-sheet-campfire.png: 24 frames,
                                                     box-reduced by 10 to 64 x 64 (GP-BANDIT-CAMP-ART, CC BY 4.0)
    game/assets/icon/icon_<size>.png                 My_Medieval_Life_Icon_Pack.zip (the app icon)
    game/assets/ui/<name>.png                        Flat Game UI Icon Pack/ (icon tiles, the button tile)
    game/assets/ui/hud_<name>.png                    16x16 Survival RPG Icons.zip (HUD status icons, HUD_ICONS)
    game/assets/ui/inventory_*.png, tab_*.png       CozyFarm_full_version.zip (the pack window, its tabs and
                                                     bag icon) and tab icons from the Assorted and Survival packs
    game/assets/prompts/<name>.png                   kenney_input-prompts_1.5.zip (keys, pad buttons, touch)
    game/assets/trees/*, icons/oak_sapling.png, icons/pine_sapling.png
                                                     the Living Forest package in private-assets/ (not in the
                                                     repository), by tools/living_forest.py (skipped, files kept,
                                                     if the package is missing)
    game/assets/terrain/*, icons/nails.png, icons/mallet.png
                                                     B14-07's ways through a cliff and its two items, by
                                                     tools/terrain_art.py (Forgotten Memories, from private-assets/,
                                                     and Miniworld's bridge)
    game/assets/music/*.ogg, game/assets/sfx/*.ogg     MUSIC-18, SFX-18: the owner's songs (release WAVs, Android's copy) and the
                                                     Cozy RPG SFX (private-assets/), encoded with ffmpeg by tools/game_audio.py
    game/assets/PROVENANCE.json                      source, path and transformation of every file

Character sheets are 29 x 8 frames of 32 px: rows are the 8 directions (S, SE, E, NE, N, NW, W,
SW), columns as listed in tools/puny_chargen.py ANIMS.

Cozy Farm animal sheets are 4 frames x 5 rows (down, up, left, right, sleep), square frames of the size
in the pack's info.txt, each given a 1 px transparent gutter (cells 2 px larger, VIS-ANIMAL-01); Puny Monsters sheets are 12 x 8 frames of 32 px in the Puny direction order.

The flat UI pack is Illustrator files; they are rasterised with pdftoppm (poppler-utils), which
must be installed.

Usage:
    python3 tools/import_game_assets.py
"""
import hashlib
import io
import json
import random
import subprocess
import tempfile

from assetzip import AssetZip, REPO
import puny_chargen
import puny_world_terrain as pwt
import animal_farm  # noqa: E402
import craftpix_plants  # noqa: E402
import living_forest
import terrain_art  # noqa: E402
import game_audio  # noqa: E402

OUT = REPO / "game" / "assets"
CAMPFIRE_SHEET = "Animated Pixel Campfire (SMStudios)/Sprite-sheet-campfire.png"
VILLAGERS, BANDITS, PLAYERS, GUARDS = 48, 6, 4, 6
ICON_ZIP = "16x16 Survival RPG Icons.zip"
COZY_ZIP = "CozyFarm_full_version.zip"
SPLAT_ZIP = "kenney_splatpack.zip"
APP_ICON_ZIP = "My_Medieval_Life_Icon_Pack.zip"
BLOOD_SPLATS = [0, 4, 9, 13, 17, 21, 26, 31]   # varied shapes from the 36
UI_PACK = "Flat Game UI Icon Pack"
# icon tiles used by the game: name -> (file, row, column) in the pack's 9-column grids
UI_ICONS = {
    "use": ("icons_set_2.ai", 7, 8), "attack": ("icons_set_2.ai", 6, 8), "fire": ("icons_set_2.ai", 4, 0),
    "pack": ("icons_set_2.ai", 3, 0), "skills": ("icons_set_1.ai", 7, 8), "menu": ("icons_set_1.ai", 1, 8),
    "close": ("icons_set_1.ai", 2, 5), "settings": ("icons_set_1.ai", 5, 2), "save": ("icons_set_1.ai", 0, 5),
    "back": ("icons_set_1.ai", 2, 1), "health": ("icons_set_2.ai", 0, 3), "hunger": ("icons_set_2.ai", 10, 6),
    "stamina": ("icons_set_2.ai", 1, 0), "coins": ("icons_set_2.ai", 6, 0), "home": ("icons_set_1.ai", 2, 0),
    "play": ("icons_set_1.ai", 1, 6), "scroll": ("icons_set_2.ai", 9, 6), "trade": ("icons_set_1.ai", 4, 1),
    "map": ("icons_set_2.ai", 5, 0), "recenter": ("icons_set_1.ai", 1, 2), "gather": ("icons_set_2.ai", 3, 4),
}
# owner, 2026-10-18 (B7-013): the action bar, the status icons and the empty gear slots draw the
# glyph alone, brown on a transparent background (with a thin cream edge so it reads over the map),
# not a white glyph on a brown tile. Names here are cut from UI_ICONS or, for the slots, from set 2.
UI_GLYPHS = {"use", "gather", "attack", "fire", "pack", "skills", "map", "menu", "recenter",
             "health", "hunger", "stamina", "coins"}
UI_SLOT_ICONS = {
    "slot_weapon": ("icons_set_2.ai", 6, 8), "slot_tool": ("icons_set_2.ai", 7, 1),
    "slot_armor": ("icons_set_2.ai", 7, 5), "slot_head": ("icons_set_2.ai", 7, 3),
    "slot_amulet": ("icons_set_2.ai", 2, 6), "slot_ring": ("icons_set_2.ai", 2, 7),
}
# a glyph for each skill (game/data/skills.json), shown beside it in the skills window
UI_SKILL_ICONS = {
    "skill_mining": ("icons_set_2.ai", 3, 3), "skill_woodcutting": ("icons_set_2.ai", 7, 1),
    "skill_smithing": ("icons_set_2.ai", 8, 5), "skill_crafting": ("icons_set_2.ai", 5, 3),
    "skill_cooking": ("icons_set_2.ai", 3, 7), "skill_combat": ("icons_set_2.ai", 8, 3),
    "skill_magic": ("icons_set_2.ai", 9, 3), "skill_trading": ("icons_set_2.ai", 6, 0),
    "skill_stealth": ("icons_set_2.ai", 4, 3), "journal": ("icons_set_2.ai", 9, 6),
}
# pixel-art status icons for the HUD from the survival pack, copied unchanged (16 px, the pack's own dark outline).
# UI-HUNGER-01 (owner, B18-DIR Part 7): a roast drumstick for the food bar, in place of the bread item's butter-block
# placeholder. The pack's "Chicken" icons are whole roast birds; its "Fowl" icons are the drumsticks, and Fowl-04
# (golden roast) reads clearest on the dark status box.
HUD_ICONS = {"hud_hunger": "Food/Fowl-04"}
UI_GLYPH_BROWN = (111, 74, 44)    # the same wood brown as the buttons
UI_GLYPH_EDGE = (246, 236, 214)   # the interface's cream text colour
UI_TILE = 128          # icon tiles are saved at this size
UI_WOOD = (111, 74, 44)  # the pack's navy recoloured to a wood brown (owner, 2026-10-18)
PROMPT_ZIP = "kenney_input-prompts_1.5.zip"
# input prompt icons shown with prompts and on the controls list: name -> member (128 px "Double" set)
PROMPTS = {name: f"Keyboard & Mouse/Double/{name}.png" for name in
           ["keyboard_b", "keyboard_e", "keyboard_f", "keyboard_i", "keyboard_l", "keyboard_space", "keyboard_escape",
            "keyboard_w", "keyboard_a", "keyboard_s", "keyboard_d", "keyboard_c", "keyboard_m", "keyboard_g", "mouse_left", "mouse_right",
            "mouse_scroll", "mouse_move", "keyboard_q", "keyboard_tab", "keyboard_shift", "keyboard_t", "keyboard_h"]}
PROMPTS.update({name: f"Xbox Series/Double/{name}.png" for name in
                ["xbox_button_a", "xbox_button_b", "xbox_button_x", "xbox_button_y", "xbox_button_view",
                 "xbox_button_menu", "xbox_stick_l", "xbox_stick_r", "xbox_stick_r_press", "xbox_lb", "xbox_rb", "xbox_dpad_down", "xbox_lt", "xbox_rt",
                 "xbox_dpad_left", "xbox_dpad_right", "xbox_stick_l_press", "xbox_dpad_up"]})
PROMPTS.update({name: f"Touch/Double/{name}.png" for name in ["touch_tap", "touch_finger_one", "touch_zoom_in",
                                                                "touch_swipe_two_move"]})
MONSTER_ZIP = "PunyMonsters.zip"
COZY_GUTTER = 1   # transparent px around each Cozy Farm animal frame (VIS-ANIMAL-01; see _gutter)
# MiniFolks forest animals (B14, LYASeeK; a loose folder, the owner's .7z extracted byte for byte): skin -> the
# outlined side-view sheet (32 px frames, the bird's 16 px; one row per animation, facing right)
FOREST_DIR = "MiniFolks Forest Animals"
FOREST = {"mini_bear": "MiniBear", "mini_boar": "MiniBoar", "mini_doe": "MiniDeer1", "mini_stag": "MiniDeer2",
          "mini_fox": "MiniFox", "mini_wolf": "MiniWolf", "mini_bunny": "MiniBunny", "mini_bird": "MiniBird"}
# game species -> (archive, member)
ANIMALS = {
    "cow": (COZY_ZIP, "full version/animals/cow animation.png"),
    "cow_brown": (COZY_ZIP, "full version/animals/cow_brown animation.png"),
    "pig": (COZY_ZIP, "full version/animals/pig animation.png"),
    "sheep": (COZY_ZIP, "full version/animals/sheep animation.png"),
    "chicken": (COZY_ZIP, "full version/animals/chicken animation.png"),
    "chicken_brown": (COZY_ZIP, "full version/animals/chicken_brown animation.png"),
    "rabbit": (COZY_ZIP, "full version/animals/bunny_animations.png"),
    "rabbit_grey": (COZY_ZIP, "full version/animals/bunny_grey animation.png"),
    # B8-029: the baby sheets (same 4 x 5 layout, smaller frames) for newborn and juvenile animals; the boar has none
    "cow_baby": (COZY_ZIP, "full version/animals/cow_baby animation.png"),
    "cow_brown_baby": (COZY_ZIP, "full version/animals/cow_baby_brown animation.png"),
    "pig_baby": (COZY_ZIP, "full version/animals/pig_baby animation.png"),
    "sheep_baby": (COZY_ZIP, "full version/animals/sheep_baby animation.png"),
    "chicken_baby": (COZY_ZIP, "full version/animals/chicken_baby animation.png"),
    "chicken_brown_baby": (COZY_ZIP, "full version/animals/chicken_baby animation.png"),      # no brown chick art: the same chick
    "rabbit_baby": (COZY_ZIP, "full version/animals/bunny_baby animation.png"),
    "rabbit_grey_baby": (COZY_ZIP, "full version/animals/bunny_baby_grey animation.png"),
    "boar": (MONSTER_ZIP, "PunyMonsters/Brown-Boar-32x32.png"),
    "boar_grey": (MONSTER_ZIP, "PunyMonsters/Dirty-Gray-Boar-32x32.png"),
}
# item id -> icon file in the survival pack (variant numbers chosen for the metal or colour)
ICONS = {
    "copper_ore": "Metal/Metal-Ore-01", "iron_ore": "Metal/Metal-Ore-02", "gold_ore": "Metal/Metal-Ore-08",
    "coal": "Stone/Coal-01", "stone": "Stone/Rock-Chunk-01", "log": "Wood/Wood-Log-01",
    "plank": "Wood/Wooden-Planks-01", "wheat": "Plants & Alchemy/Herb-Bundle-01",
    "pottage": "Metal/Metal-Pot-01", "roast_meat": "Food/Steak-01", "ale": "Liquid/Brew-01",
    "meat": "Food/Meat-01", "hide": "Textile/Deer-Pelt-07",
    # PL2-004: a grey rodent pelt for the rabbit; the pack has no feather, so a golden leaf stands in (BUILD_DECISIONS)
    "rabbit_pelt": "Textile/Rodent-Pelt-01", "feather": "Plants & Alchemy/Leaf-05", "leather": "Textile/Leather-Fabric-07",
    "iron_bar": "Metal/Metal-Ingot-02", "copper_bar": "Metal/Metal-Ingot-01", "gold_bar": "Metal/Metal-Ingot-08",
    "pickaxe": "Tools/Pickaxe-02", "axe": "Tools/Axe-02", "iron_sword": "Tools/Sword-02",
    "copper_sword": "Tools/Sword-01", "leather_armor": "Armour/Leather-Jacket-08",
    "iron_armor": "Armour/Metal-Chestplate-02", "coins": "Metal/Metail-Coins-08",
    "hammer": "Tools/Hammer-02", "fireball": "Tools/Magic-Staff-05",
    "leather_cap": "Armour/Leather-Cap-07", "iron_helmet": "Armour/Metal-Helm-05",
    # wild plants (B8-015/B8-016): yellow flower, red and blue berries, the flower tonic
    "flower": "Plants & Alchemy/Flower-09", "red_berries": "Plants & Alchemy/Berry-05",
    "blueberries": "Plants & Alchemy/Berry-16", "herbal_tonic": "Plants & Alchemy/Herbal-Potion-01",
    # healing goods (PL1-04): white silk cloth as the bandage, a green leaf for the poultice, the small
    # and the large red potion for the two tonics
    "linen_bandage": "Textile/Silk-Fabric-04", "herbal_poultice": "Plants & Alchemy/Leaf-11",
    "healing_tonic": "Liquid/Small-Potion-05", "strong_healing_tonic": "Liquid/Large-Potion-05",
    # locks and picks (PL2-002): a thin iron arrow-shaft as the lockpick, a lump of iron as the padlock
    "lockpick": "Tools/Arrow-05", "padlock": "Metal/Metal-Nugget-02",
    # the hand plough (PL2-015): the pack has no plough, so its hoe stands in
    "plough": "Tools/Hoe-02",
    # cart parts and the handcart (B14): stand-ins until the owner's own art, a round wooden shield as the wheel,
    # a stick as the axle, an iron slab as the ironwork and a plank slab as the cart
    "cart_wheel": "Armour/Wooden-Shield-01", "cart_axle": "Wood/Stick-01", "cart_ironwork": "Blocks/Metal-Slab-02",
    "handcart": "Blocks/Wood-Plank-Slab-03",
    # MIN-C prospecting: the brown leather pack as the prospector's kit (hammer, chisel and sample bags in a satchel),
    # the reddish rock fragments as a rock sample
    "prospecting_kit": "Tools/Backpack-05", "ore_sample": "Stone/Rocks-10",
    # MIN-E open-pit earth: the grass-topped dirt block as topsoil, the plain brown dirt block as dirt (subsoil), the
    # grey pebbles as spoil (broken rock and gravel)
    "topsoil": "Blocks/Dirt-Block-01", "dirt": "Blocks/Dirt-Block-13", "spoil": "Stone/Rocks-02",
    # MIN-F underground works (stand-ins: the pack has no pit prop, rail or mine cart): the dark squared log block as
    # the timber support (a prop and cap), a plank as the track section, the dark iron tub as the minecart's body
    "timber_support": "Blocks/Wood-Log-Block-06", "track_section": "Wood/Wood-Plank-Type-B-04",
    "minecart": "Metal/Metal-Bucket-02",
    # STONE-01: the light grey dressed block as the finished building block (squared faces), apart from raw stone's chunk
    "building_block": "Blocks/Stone-Block-02",
    # STONE-06: the grey iron-bladed knife stands in for the iron chisel (the pack has no chisel)
    "chisel": "Tools/Knife-05",
    # STONE-04: pale grey rock fragments for the rubble a dressing leaves
    "rubble": "Stone/Rocks-05",
    # MIN-F2: a bundle of sticks stands in for the ladder (the pack has none)
    "ladder": "Wood/Sticks-01",
    # MIN-SHOVEL: the grey iron-headed shovel as the shovel; the plain wooden shovel as the carpenter's haft (a
    # medieval shovel was a wooden blade and handle shod with iron); a grey iron slab as the smith's blade (its iron shoe)
    "shovel": "Tools/Shovel-05", "shovel_haft": "Tools/Shovel-15", "shovel_blade": "Blocks/Metal-Slab-05",
    # DVW-B3-LUX luxury imports: the orange-red dried herb bundle as the spices (the pack has no spice jar), a crimson silk
    # fabric as the fine cloth (the white one is the bandage)
    "spice": "Plants & Alchemy/Herb-Bundle-04", "fine_cloth": "Textile/Silk-Fabric-16",
}
# Cozy Farm's item sheets (PL2-015): item id -> (sheet member, column, row) of the 16 x 16 cell. items.png is the
# produce (10 columns: vegetables, eggs, milk, wool and cloth), seeds.png the seed packets (7 columns).
COZY_ITEMS = {
    "carrot": ("full version/ui/items.png", 0, 0), "potato": ("full version/ui/items.png", 5, 0),
    "milk": ("full version/ui/items.png", 0, 3), "cheese": ("full version/ui/items.png", 3, 3),
    "egg": ("full version/ui/items.png", 2, 4), "wool": ("full version/ui/items.png", 0, 5),
    "wool_cloth": ("full version/ui/items.png", 4, 5),
    "wheat_seed": ("full version/farming/seeds.png", 2, 1), "carrot_seed": ("full version/farming/seeds.png", 0, 0),
    "potato_seed": ("full version/farming/seeds.png", 5, 0), "herb_seed": ("full version/farming/seeds.png", 2, 2),
    # SEED-02 propagation material: the yellow-flower packet for wild flower seed; the red and the blue berry-cluster
    # packets stand in for the two bushes' cuttings (the packs have no cutting or sprig; the packet says which bush)
    "flower_seed": ("full version/farming/seeds.png", 1, 5),
    "red_berry_cutting": ("full version/farming/seeds.png", 0, 3), "blue_berry_cutting": ("full version/farming/seeds.png", 5, 3),
}
# VIS-CROP-01 (owner, B18-DIR Part 9): the plants drawn over every field cell, one 16 px plant per cell, from Cozy
# Farm's crop sheet (farming/crops.png: one crop a row, seeds then the growth stages left to right; the rows match the
# seed packets used as the seed icons). game crop -> (sheet row, columns for the four growing quarters, the ripe column).
# The herb (it yields wild flowers) is the small yellow flower, the crop the herb seed packet's colour; its row has one
# stage fewer.
CROP_SHEET = "full version/farming/crops.png"
CROP_ROWS = {"wheat": (9, [1, 2, 3, 4], 5), "carrot": (0, [1, 2, 3, 4], 5), "potato": (5, [1, 2, 3, 4], 5),
             "herb": (36, [1, 1, 2, 3], 4)}
CROP_ORDER = ["wheat", "carrot", "potato", "herb"]      # the rows of game/assets/tiles/crops.png (CropView.ROWS)
STUBBLE_FROM = 11      # a cut wheat field's stubble: the ripe wheat's pixels from this row down (the stalks' feet)
JEWELRY_ZIP = "16x16 Jewelry RPG Icons.zip"
# item id -> icon in the jewelry pack (plain metals; the amulet has a red stone)
JEWELRY = {"copper_ring": "Rings/Ring-01", "gold_ring": "Rings/Ring-16", "amulet": "Necklaces/Necklace-05",
           "jewellery": "Necklaces/Necklace-28"}      # DVW-B3-LUX: the gold chain with a blue stone
# Cozy Farm's inventory window (full version/ui/inventory.png, 848 x 1360): the panel with flat tabs
# and the 9 x 3 bag grid is at INV_PANEL; below it, 8 copies with tab 0..7 raised start at INV_RAISED
# rows, INV_RAISED_STEP apart. A raised tab stands INV_HEAD px higher than the flat strip.
INV_PANEL = (0, 4, 293, 128)
INV_RAISED, INV_RAISED_STEP, INV_HEAD, INV_STRIP = 220, 144, 8, 16
INV_BAG = (160, 192, 176, 208)                    # the bag icon in inventory_chopped.png
SKILLS_BOOK = ("16x16 Assorted RPG Icons (partial)/books.png", 8, 8)   # sheet, column, row of a gilt book
# Medieval-village look: natural skin tones (rows 0-6 of the skin ramp), no horns, and headwear
# from a short list per kind (None = bare head).
# natural hair colours: rows of the generator's hair ramp (auburn, dark brown, black, grey, white,
# blonde); the other rows are pure reds, greens and blues
NATURAL_HAIR = [0, 1, 2, 3, 4, 6]
HATS = {
    "villager": [None] * 7 + ["villager-straw-hat", "rogue-hood", "ranger-hat", "hunter-hat", "traveller-straw-hat"],
    "player": [None, "villager-straw-hat", "ranger-hat"],
    "bandit": ["thief-bandana", "assassin-bandana", "rogue-hood"],
    "guard": ["soldier-helm", "knight-helm", "novice-helm"],
}
# CC-01 (owner, 2026-10-22: an ordinary medieval civilian, appearance only): what character creation offers.
# None = "none". No headwear, armour, foreign or fantasy clothes, gloves, horns or ears; human only.
CREATION_PICKS = {
    "race": ["human"],
    "hair": [None, "f1", "f2", "f3", "f4", "m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9"],
    "facial-hair": [None, "beard1", "beard2", "mustache"],
    "eyelashes": [None, "f1", "f2", "f3", "m1", "m2", "n1", "n2", "n3"],
    "clothes": ["basic", "tunic"],
    "shoes": [None, "leather-boots"],
}
# swatch rows offered per colour selection: natural skin (0-6); natural hair: golden, brown, black, grey, white
# (NATURAL_HAIR without row 6, which is lemon yellow (255, 255, 27) in the game, not a blonde; the other rows are
# pure reds, greens, blues and magentas); eyes without the red (10, 11) and blank white (13) rows; every row of
# the clothes, tunic and leather ramps (plain dyed cloth and leather)
CREATION_SWATCHES = {
    "skin": list(range(7)), "hair": [0, 1, 2, 3, 4], "eyes": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12],
    "clothes": list(range(7)), "tunic": list(range(5)), "leather_shoes": list(range(3)),
}
CREATION_LINKED = {"facial_hair": "hair"}    # a beard takes the hair's colour, as the importer's looks always had
ALWAYS_LAYERS = {"eyes": "eyes", "weapon-overlay": "weapon-overlay"}   # drawn without a pick (puny_chargen.render)
HUMAN_ONLY = ["eyes", "eyelashes"]
# ARMOR-01 (owner Option A, 2026-10-22; docs/DECISIONS.md): worn item id -> the layer it draws while worn. iron_armor is
# the pack's metal-armour clothes layer, iron_helmet its novice-helm (a plain open iron helm; the face stays
# readable), both on metal ramp row 1 (the cool steel grey; row 0 is the warm reference grey, rows 2-3 gold).
# leather_armor and leather_cap have no art: drawn as nothing extra. Not offered by creation.
WORN_LAYERS = {
    "iron_armor": {"layer": "clothes", "option": "metal-armour", "swatches": {"metal_armour": 1}},
    "iron_helmet": {"layer": "headwear", "option": "novice-helm", "swatches": {"metal_headwear": 1}},
}


def civilian_recipe(recipe):
    """The part of a puny_chargen recipe the run-time look keeps: the creation layers' picks and the swatches
    the layers drawn actually use. Drawing it gives the same sheet as puny_chargen.render(recipe) when the
    recipe has nothing outside the creation layers."""
    picks = {k: recipe["picks"].get(k) for k in CREATION_PICKS}
    sels = {"eyes"}
    for layer, code in picks.items():
        if code is not None:
            sels |= {sel for _, sel in dict(STYLE_CHOICES[layer])[code]}
    return {"picks": picks, "swatches": {s: recipe["swatches"][s] for s in sorted(sels)}}


STYLE_CHOICES = {}


def _import_character_layers(record, style, zip_name):
    """CC-01: the layer sheets creation offers (copied unchanged) and game/data/character_style.json, the rules
    CharacterLook (game/scripts/view/character_look.gd) draws by, all taken from puny_chargen's port of the
    pack's manifest.tds: draw order, which ramp and colour selection recolours each layer, and the ramps."""
    layers, used_ramps = {}, {"eyes"}
    wanted = {layer: [c for c in codes if c is not None] for layer, codes in CREATION_PICKS.items()}
    wanted.update({layer: [code] for layer, code in ALWAYS_LAYERS.items()})
    for w in WORN_LAYERS.values():
        wanted.setdefault(w["layer"], [])
        if w["option"] not in wanted[w["layer"]]:
            wanted[w["layer"]].append(w["option"])
    for layer in puny_chargen.DRAW_ORDER:
        if layer not in wanted:
            continue
        pairs_of = dict(style.choices.get(layer, []))
        layers[layer] = {}
        for code in wanted[layer]:
            pairs = [["eyes", "eyes"]] if layer == "eyes" else [list(p) for p in pairs_of.get(code, [])]
            member = f"assets/{layer}/{code}.png"
            dest = OUT / "characters" / "layers" / layer / f"{code}.png"
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(style.z.read(member))
            record(dest, zip_name, member, "copied unchanged (CC-01 run-time layer; recoloured in the game by its ramps)")
            layers[layer][code] = {"sheet": "res://" + str(dest.relative_to(REPO / "game")), "ramps": pairs}
            used_ramps |= {r for r, _ in pairs}
    ramps = {}
    for r in sorted(used_ramps):
        img = style.ramps[r].convert("RGBA")
        ramps[r] = [["%02x%02x%02x%02x" % img.getpixel((x, y)) for x in range(img.width)] for y in range(img.height)]
    selections = {sel: ramp for sel, ramp in sorted(puny_chargen.SELECTIONS.items()) if ramp in used_ramps
                  and any(sel == s for lay in layers.values() for o in lay.values() for _, s in o["ramps"])}
    data = {
        "format": "mml-character-style/1",
        "source": zip_name + " (rules: tools/puny_chargen.py, a port of the pack's manifest.tds)",
        "dim": puny_chargen.DIM, "frames": puny_chargen.FRAMES, "directions": puny_chargen.DIRECTIONS,
        "draw_order": puny_chargen.DRAW_ORDER, "always": ALWAYS_LAYERS, "human_only": HUMAN_ONLY,
        "selections": selections, "ramps": ramps, "layers": layers,
        "creation": {"picks": CREATION_PICKS, "swatches": CREATION_SWATCHES, "linked": CREATION_LINKED},
        # ARMOR-01: worn item id -> {"layer", "option", "swatches", "hides": [layers]} (WORN_LAYERS above)
        "worn_layers": WORN_LAYERS,
    }
    (REPO / "game" / "data" / "character_style.json").write_text(json.dumps(data, indent=1) + "\n")


def _gutter(sheet, cols, rows, gutter):
    """A copy of an unpadded frame grid with every frame centred in a cell 2 x `gutter` px larger. VIS-ANIMAL-01:
    Cozy Farm's animal frames touch their cells' edges (feet on the bottom edge, noses and tails at the sides), so a
    frame drawn at a fractional zoom or a snapped sub-pixel position could sample its neighbour's edge row: the
    stray strips seen over pigs, sheep and chickens. With transparent gutters nothing of a neighbour is in reach.
    The frames' pixels and their centres are unchanged, so AnimalSprite's grid counts and feet offset still hold."""
    from PIL import Image
    fw, fh = sheet.width // cols, sheet.height // rows
    assert fw * cols == sheet.width and fh * rows == sheet.height, f"{sheet.size} is not a {cols} x {rows} grid"
    sheet = sheet.convert("RGBA")
    out = Image.new("RGBA", ((fw + 2 * gutter) * cols, (fh + 2 * gutter) * rows))
    for r in range(rows):
        for c in range(cols):
            frame = sheet.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh))
            out.paste(frame, (c * (fw + 2 * gutter) + gutter, r * (fh + 2 * gutter) + gutter))
    return out


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _rasterise(ai_file, dpi):
    """Render the first page of an Illustrator (PDF-compatible) file to an RGB image."""
    from PIL import Image
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["pdftoppm", "-r", str(dpi), "-png", "-f", "1", "-l", "1", str(REPO / UI_PACK / ai_file),
                        tmp + "/page"], check=True)
        Image.MAX_IMAGE_PIXELS = None
        return Image.open(tmp + "/page-1.png").convert("RGB")


def _bands(counts, threshold):
    out, start = [], None
    for i, c in enumerate(list(counts) + [0]):
        if c > threshold and start is None:
            start = i
        elif c <= threshold and start is not None:
            out.append((start, i))
            start = None
    return out


# quest markers over a quest giver's head (owner, 2026-10-18): what the quest is about
MARKERS = {
    "skill": "Wood/Paper-03",          # a rolled scroll, given a red wax seal below
    "food": "Plants & Alchemy/Herb-Bundle-01",
    "mineral": "Metal/Metal-Ore-02",
    "combat": "Tools/Sword-01",        # crossed with its mirror image below
    "wood": "Wood/Wood-Log-01",
    "tool": "Tools/Axe-02",
}


def _outlined(img):
    """A 16 px icon on an 18 px canvas with a 1 px dark outline, so it reads over grass and roofs."""
    from PIL import Image
    out = Image.new("RGBA", (18, 18))
    dark = Image.new("RGBA", img.size, (24, 16, 10, 255))
    mask = img.getchannel("A").point(lambda a: 255 if a > 0 else 0)
    for dx, dy in ((0, 1), (2, 1), (1, 0), (1, 2), (0, 0), (2, 2), (0, 2), (2, 0)):
        out.paste(dark, (dx, dy), mask)
    out.alpha_composite(img, (1, 1))
    return out


def _pennant():
    """The story-quest marker: a green swallow-tailed pennant with a gold rim on a pole with a gold
    finial, drawn in the 16 px style of the Survival icons."""
    from PIL import Image
    img = Image.new("RGBA", (16, 16))
    px = img.load()
    pole, finial, green, light, gold = (92, 60, 34, 255), (236, 196, 72, 255), (40, 140, 64, 255), (96, 196, 110, 255), (220, 178, 60, 255)
    for y in range(3, 16):
        px[3, y] = pole
    for x, y in ((3, 1), (2, 2), (3, 2), (4, 2)):
        px[x, y] = finial
    rows = {3: range(4, 14), 4: range(4, 14), 5: range(4, 12), 6: range(4, 11), 7: range(4, 12), 8: range(4, 14), 9: range(4, 14)}
    for y, xs in rows.items():
        for x in xs:
            px[x, y] = green
    for x in range(4, 13):
        px[x, 4] = light                                   # a fold catching the light
    for y in (3, 9):
        for x in range(4, 14):
            px[x, y] = gold                                # gold rim, top and bottom
    return img


def _star():
    """The employer marker (PL1-09): a bright five-point gold star with a pale highlight, drawn in the
    16 px style; outlined like the other markers."""
    from PIL import Image
    img = Image.new("RGBA", (16, 16))
    px = img.load()
    gold, light, deep = (255, 214, 56, 255), (255, 244, 170, 255), (222, 160, 24, 255)
    rows = {1: (7, 8), 2: (7, 8), 3: (6, 9), 4: (6, 9), 5: (0, 15), 6: (1, 14), 7: (3, 12), 8: (4, 11),
            9: (4, 11), 10: (3, 12), 11: (3, 12), 12: (2, 6), 13: (2, 5)}
    for y, (a, b) in rows.items():
        for x in range(a, b + 1):
            px[x, y] = gold
    for y in (11, 12, 13):                                   # the two feet, apart
        for x in range(7, 9):
            px[x, y] = (0, 0, 0, 0)
    for y, (a, b) in {12: (9, 13), 13: (10, 13)}.items():
        for x in range(a, b + 1):
            px[x, y] = gold
    for x, y in ((7, 3), (7, 4), (6, 5), (7, 6), (5, 6), (4, 7)):
        px[x, y] = light                                     # the light catching the upper left
    for x, y in ((8, 7), (9, 8), (10, 9), (11, 10), (4, 11), (3, 12)):
        px[x, y] = deep
    return img


def _import_markers(record, survival):
    import io
    from PIL import Image, ImageOps
    out = OUT / "markers"
    out.mkdir(parents=True, exist_ok=True)
    for kind, rel in sorted(MARKERS.items()):
        member = f"16x16 Survival RPG Icons/{rel}.png"
        img = Image.open(io.BytesIO(survival.read(member))).convert("RGBA")
        how = "1 px dark outline on an 18 px canvas"
        if kind == "combat":
            crossed = img.copy()
            crossed.alpha_composite(ImageOps.mirror(img))
            img = crossed
            how = "crossed with its mirror image; " + how
        if kind == "skill":
            img = _seal(img)                                              # a red wax seal
            how = "a red wax seal added; " + how
        dest = out / f"{kind}.png"
        _outlined(img).save(dest)
        record(dest, ICON_ZIP, member, how)
    dest = out / "story.png"
    _outlined(_pennant()).save(dest)
    prov_note = "generated: a green swallow-tailed pennant with a gold rim on a pole (story quests), 1 px outline"
    record(dest, "", "", prov_note)
    dest = out / "star.png"
    _outlined(_star()).save(dest)
    record(dest, "", "", "generated: a bright five-point gold star over the employer who is owed payment (PL1-09), 1 px outline")


def _import_ui(record):
    """Icon tiles from the flat UI pack (white glyphs on rounded navy squares), cut from the
    9-column grids with the page's grey background made transparent, and set 3's plain slate
    button square, which every button in the game is drawn with."""
    import numpy as np
    from PIL import Image
    ui = OUT / "ui"
    ui.mkdir(parents=True, exist_ok=True)
    pages = {}
    glyphs = {**UI_SLOT_ICONS, **UI_SKILL_ICONS}
    for name, (ai_file, row, col) in sorted({**UI_ICONS, **glyphs}.items()):
        if ai_file not in pages:
            page = np.asarray(_rasterise(ai_file, 150)).astype(np.float64)
            bg = page[5, 5]
            mask = np.abs(page - bg).sum(axis=2) > 30
            pages[ai_file] = (page, bg, _bands(mask.sum(axis=1), 50), _bands(mask.sum(axis=0), 50))
        page, bg, rows, cols = pages[ai_file]
        (y0, y1), (x0, x1) = rows[row], cols[col]
        tile = page[y0:y1, x0:x1]
        navy = tile[tile.shape[0] // 2, 4]
        # alpha from how far a pixel is from the background towards the tile colour (soft corners)
        alpha = np.clip(np.abs(tile - bg).sum(axis=2) / np.abs(navy - bg).sum(), 0.0, 1.0)
        rgb = np.where(alpha[..., None] < 1.0, navy, tile)
        # recolour: how far each pixel is from the navy towards the white glyph, applied to wood brown
        t = np.clip((rgb.mean(axis=2) - navy.mean()) / (255.0 - navy.mean()), 0.0, 1.0)[..., None]
        wood = np.array(UI_WOOD, dtype=np.float64)
        rgb = wood + t * (255.0 - wood)
        dest = ui / f"{name}.png"
        if name in UI_GLYPHS or name in glyphs:
            _glyph(t[..., 0] * alpha).resize((UI_TILE, UI_TILE), Image.LANCZOS).save(dest)
            record(dest, UI_PACK, ai_file, f"rasterised at 150 dpi with pdftoppm; grid row {row}, column {col}; "
                   f"the white glyph only, recoloured to brown {UI_GLYPH_BROWN} on a transparent background with a "
                   f"{UI_GLYPH_EDGE} edge; resized to {UI_TILE} px")
            continue
        img = Image.fromarray(np.dstack([rgb, alpha * 255.0]).round().astype(np.uint8), "RGBA")
        img.resize((UI_TILE, UI_TILE), Image.LANCZOS).save(dest)
        record(dest, UI_PACK, ai_file, f"rasterised at 150 dpi with pdftoppm; grid row {row}, column {col}; "
               f"background made transparent; navy recoloured to wood brown {UI_WOOD}; resized to {UI_TILE} px")
    # set 3's slate button colour, as a plain square cut from a blank level tile of the dark scheme
    page = _rasterise("Flat_game_UI_set_3.ai", 100)
    button = page.crop((205, 655, 245, 695))
    button = Image.new("RGB", button.size, UI_WOOD) if len(button.getcolors()) == 1 else button
    dest = ui / "button.png"
    button.save(dest)
    record(dest, UI_PACK, "Flat_game_UI_set_3.ai", "rasterised at 100 dpi with pdftoppm; a 40 px square "
           f"from a blank tile of the dark LEVELS window (the pack's button colour), recoloured to wood brown {UI_WOOD}")


def _glyph(cover):
    """A glyph (its coverage, 0-1) drawn brown on a transparent background, inside a thin cream edge
    (the glyph's coverage grown by a few pixels) so it reads on grass, stone and dark windows alike."""
    import numpy as np
    from PIL import Image, ImageFilter
    h, w = cover.shape
    pad = 6
    c = np.zeros((h + 2 * pad, w + 2 * pad))
    c[pad:pad + h, pad:pad + w] = cover
    glyph = Image.fromarray((c * 255).round().astype(np.uint8), "L")
    edge = np.asarray(glyph.filter(ImageFilter.MaxFilter(7))).astype(np.float64) / 255.0
    brown = np.array(UI_GLYPH_BROWN, dtype=np.float64)
    cream = np.array(UI_GLYPH_EDGE, dtype=np.float64)
    rgb = cream + c[..., None] * (brown - cream)
    alpha = np.maximum(edge, c)
    return Image.fromarray(np.dstack([rgb, alpha * 255.0]).round().astype(np.uint8), "RGBA")


def _seal(img):
    """The red wax seal the quest marker's scroll has (see _import_markers)."""
    for x, y in ((7, 9), (8, 9), (7, 10), (8, 10), (6, 10), (9, 10), (7, 11), (8, 11)):
        img.putpixel((x, y), (168, 28, 24, 255))
    img.putpixel((7, 10), (214, 70, 56, 255))
    return img


def _import_crops(record):
    """The field plants sheet (CropView): a row per crop of CROP_ORDER, 16 px cells: columns 0-3 the plant a quarter,
    half, three quarters and nearly grown, column 4 ripe, and on the wheat row column 5 the stubble of a cut field
    (the ripe wheat cut to its lowest rows: no pack has stubble)."""
    from PIL import Image
    sheet = AssetZip(COZY_ZIP).image(CROP_SHEET)
    out = Image.new("RGBA", (6 * 16, len(CROP_ORDER) * 16))

    def cell(row, col):
        return sheet.crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16))
    parts = []
    for r, crop in enumerate(CROP_ORDER):
        row, growing, ripe = CROP_ROWS[crop]
        for k, col in enumerate(growing + [ripe]):
            out.paste(cell(row, col), (k * 16, r * 16))
        parts.append(f"{crop}: row {row}, columns {growing} growing, {ripe} ripe")
    stubble = cell(CROP_ROWS["wheat"][0], CROP_ROWS["wheat"][2])
    stubble.paste(Image.new("RGBA", (16, STUBBLE_FROM)), (0, 0))
    out.paste(stubble, (5 * 16, 0))
    dest = OUT / "tiles" / "crops.png"
    out.save(dest)
    record(dest, COZY_ZIP, CROP_SHEET, "16 px cells rearranged, a row per crop (" + "; ".join(parts) + "); the wheat "
           f"row's column 5 is its ripe plant with the rows above {STUBBLE_FROM} cleared (stubble)")


def _import_inventory(record, survival):
    """The pack window from Cozy Farm's inventory sheet: the panel with flat tabs (8 px of empty
    headroom on top, where a raised tab reaches), a strip of the 8 tab rows with each tab raised in
    turn (drawn over the panel's top rows for the selected tab), and the tab icons."""
    import io
    import numpy as np
    from PIL import Image
    ui = OUT / "ui"
    ui.mkdir(parents=True, exist_ok=True)
    cozy = AssetZip(COZY_ZIP)
    member = "full version/ui/inventory.png"
    sheet = Image.open(io.BytesIO(cozy.read(member))).convert("RGBA")
    x0, y0, x1, y1 = INV_PANEL
    panel = Image.new("RGBA", (x1 - x0, y1 - y0 + INV_HEAD))
    panel.paste(sheet.crop(INV_PANEL), (0, INV_HEAD))
    tabs = Image.new("RGBA", (x1 - x0, INV_STRIP * 8))
    for i in range(8):
        top = INV_RAISED + i * INV_RAISED_STEP
        raised = sheet.crop((x0, top, x1, top + INV_STRIP))
        # below the strip the raised copies match the panel (checked so a misplaced crop fails here)
        below = np.asarray(sheet.crop((x0, top + INV_STRIP, x1, top + 34)))
        assert (below == np.asarray(panel)[INV_STRIP:34]).all(), f"tab {i}: raised copy does not line up"
        tabs.paste(raised, (0, i * INV_STRIP))
    dest = ui / "inventory_panel.png"
    panel.save(dest)
    record(dest, COZY_ZIP, member, f"crop {INV_PANEL} (flat tabs, 9 x 3 bag grid) with {INV_HEAD} px of empty headroom on top")
    dest = ui / "inventory_tabs.png"
    tabs.save(dest)
    record(dest, COZY_ZIP, member, f"the top {INV_STRIP} rows of the 8 copies with one tab raised (rows from y {INV_RAISED}, "
           f"every {INV_RAISED_STEP}), stacked: row i has tab i raised")
    member = "full version/ui/inventory_chopped.png"
    dest = ui / "tab_all.png"
    Image.open(io.BytesIO(cozy.read(member))).convert("RGBA").crop(INV_BAG).save(dest)
    record(dest, COZY_ZIP, member, f"crop {INV_BAG}: Cozy Farm's bag icon (the All tab)")
    sheet_path, col, row = SKILLS_BOOK
    dest = ui / "tab_skills.png"
    Image.open(REPO / sheet_path).convert("RGBA").crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16)).save(dest)
    record(dest, sheet_path.split("/")[0], sheet_path.split("/")[1], f"16 px cell column {col}, row {row}: a gilt book (the Skills tab)")
    member = f"16x16 Survival RPG Icons/{MARKERS['skill']}.png"
    dest = ui / "tab_journal.png"
    _seal(Image.open(io.BytesIO(survival.read(member))).convert("RGBA")).save(dest)
    record(dest, ICON_ZIP, member, "a red wax seal added (the quest marker's scroll, without its outline): the Journal tab")


def main():
    prov = []

    def record(dest, source, member, how):
        prov.append({"file": str(dest.relative_to(REPO / "game")), "source": source, "member": member,
                     "transform": how, "sha256": sha(dest)})

    tiles = OUT / "tiles"
    tiles.mkdir(parents=True, exist_ok=True)
    paid = AssetZip("PUNY-WORLD-PAID_v1.zip")
    member = "PUNY-WORLD-PAID_v1/Tiled/punyworld-tiles.png"
    (tiles / "punyworld-tiles.png").write_bytes(paid.read(member))
    record(tiles / "punyworld-tiles.png", "PUNY-WORLD-PAID_v1.zip", member, "copied unchanged")
    free_img = pwt.load(AssetZip(pwt.ZIP))[0]
    free_img.save(tiles / "punyworld-overworld-tiles.png")
    record(tiles / "punyworld-overworld-tiles.png", pwt.ZIP, "image of " + pwt.TSX, "decoded and re-saved as PNG")

    chars = OUT / "characters"
    chars.mkdir(parents=True, exist_ok=True)
    style = puny_chargen.Style()
    zip_name = "PUNY_CHARACTERS_v2.1_tdsm-2026.zip"
    STYLE_CHOICES.update(style.choices)
    _import_character_layers(record, style, zip_name)
    groups = (("villager", VILLAGERS, 1000), ("bandit", BANDITS, 2000), ("player", PLAYERS, 3000),
              ("guard", GUARDS, 4000))
    for kind, count, seed0 in groups:
        for i in range(count):
            rng = random.Random(seed0 + i)
            recipe = style.random_recipe(rng, {"ears-&-horns": 1.0})
            recipe["picks"]["race"] = "human"
            recipe["picks"]["headwear"] = rng.choice(HATS[kind])
            recipe["swatches"]["skin"] = rng.randrange(7)
            recipe["swatches"]["hair"] = recipe["swatches"]["facial_hair"] = rng.choice(NATURAL_HAIR[:4] + NATURAL_HAIR[5:])
            img = style.render(recipe)
            dest = chars / f"{kind}_{i:02d}.png"
            img.save(dest)
            record(dest, zip_name, "assets/* layers per recipe",
                   f"tools/puny_chargen.py recipe seed {seed0 + i}, human, natural skin, headwear per kind: "
                   + json.dumps(recipe["picks"], sort_keys=True))
    # player appearances for character creation: 4 faces per sex, each in plain clothes or a tunic
    looks = []
    faces = {"male": [("m2", None), ("m5", "beard1"), ("m7", "mustache"), ("m9", None)],
             "female": [("f1", None), ("f2", None), ("f3", None), ("f4", None)]}
    for sex, rows in faces.items():
        for i, (hair, beard) in enumerate(rows):
            for outfit in ("basic", "tunic"):
                seed = 5000 + len(looks)
                rng = random.Random(seed)
                recipe = style.random_recipe(rng, {"ears-&-horns": 1.0})
                recipe["picks"].update({"race": "human", "hair": hair, "facial-hair": beard, "headwear": None,
                                        "eyelashes": ("f" if sex == "female" else "m") + "1", "jaw": None,
                                        "clothes": outfit, "shoes": "leather-boots", "gloves": None})
                recipe["swatches"]["skin"] = i * 2 % 7
                recipe["swatches"]["hair"] = recipe["swatches"]["facial_hair"] = [1, 0, 2, 6][i]
                img = style.render(recipe)
                name = f"player_{sex[0]}{i}_{outfit}"
                dest = chars / f"{name}.png"
                img.save(dest)
                record(dest, zip_name, "assets/* layers per recipe",
                       f"tools/puny_chargen.py recipe seed {seed}, {sex}, {outfit} clothes: " + json.dumps(recipe["picks"], sort_keys=True))
                looks.append({"id": name, "sex": sex, "face": i, "outfit": outfit, "sprite": f"res://assets/characters/{name}.png",
                              "recipe": civilian_recipe(recipe)})
    # mml-appearances/2: each look carries its recipe, which saves holding only the look or its sprite migrate to
    (REPO / "game" / "data" / "appearances.json").write_text(json.dumps({"format": "mml-appearances/2", "looks": looks}, indent=1) + "\n")
    icons = OUT / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    iz = AssetZip(ICON_ZIP)
    for item, rel in sorted(ICONS.items()):
        member = f"16x16 Survival RPG Icons/{rel}.png"
        dest = icons / f"{item}.png"
        dest.write_bytes(iz.read(member))
        record(dest, ICON_ZIP, member, "copied unchanged")
    cz = AssetZip(COZY_ZIP)
    for item, (member, col, row) in sorted(COZY_ITEMS.items()):
        dest = icons / f"{item}.png"
        cz.image(member).crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16)).save(dest)
        record(dest, COZY_ZIP, member, f"the 16 x 16 cell at column {col}, row {row}, cut out")
    jz = AssetZip(JEWELRY_ZIP)
    for item, rel in sorted(JEWELRY.items()):
        member = f"16x16 Jewelry RPG Icons/{rel}.png"
        dest = icons / f"{item}.png"
        dest.write_bytes(jz.read(member))
        record(dest, JEWELRY_ZIP, member, "copied unchanged")
    member = "full version/tiles/tiles.png"
    (tiles / "cozyfarm-tiles.png").write_bytes(AssetZip(COZY_ZIP).read(member))
    record(tiles / "cozyfarm-tiles.png", COZY_ZIP, member, "copied unchanged")
    _import_crops(record)
    animals = OUT / "animals"
    animals.mkdir(parents=True, exist_ok=True)
    for species, (zname, member) in sorted(ANIMALS.items()):
        dest = animals / f"{species}.png"
        if zname == COZY_ZIP:
            sheet = _gutter(AssetZip(zname).image(member), 4, 5, COZY_GUTTER)
            sheet.save(dest)
            record(dest, zname, member, f"each frame of the 4 x 5 grid moved into a cell {2 * COZY_GUTTER} px larger, centred "
                   f"({COZY_GUTTER} px of transparent gutter on every side), pixels unchanged")
            continue
        dest.write_bytes(AssetZip(zname).read(member))
        record(dest, zname, member, "copied unchanged")
    for skin, name in sorted(FOREST.items()):
        dest = animals / f"{skin}.png"
        dest.write_bytes((REPO / FOREST_DIR / "Outline" / f"{name}.png").read_bytes())
        record(dest, FOREST_DIR, f"Outline/{name}.png", "copied unchanged")
    # starter-kit icons from Cozy Farm's item sheet (16 px cells) and tinted copies of survival icons
    from PIL import Image
    import io
    cozy_items = Image.open(io.BytesIO(AssetZip(COZY_ZIP).read("full version/ui/items.png"))).convert("RGBA")

    def cell(col, row):
        return cozy_items.crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16))

    def tint(img, rgb, amount):
        out = img.copy()
        px = out.load()
        for y in range(out.height):
            for x in range(out.width):
                r, g, b_, a_ = px[x, y]
                if a_:
                    px[x, y] = (int(r + (rgb[0] - r) * amount), int(g + (rgb[1] - g) * amount), int(b_ + (rgb[2] - b_) * amount), a_)
        return out

    kit = {
        "bread": (cell(2, 3), "full version/ui/items.png", "cell (2,3), Cozy Farm's butter block, used as a placeholder loaf"),
        "apple": (cell(0, 2), "full version/ui/items.png", "cell (0,2), apple"),
        "rotten_apple": (tint(cell(0, 2), (90, 70, 30), 0.55), "full version/ui/items.png", "cell (0,2), apple, tinted brown 55% (rotten)"),
        "plain_clothes": (cell(4, 5), "full version/ui/items.png", "cell (4,5), white cloth"),
    }
    for item, (img, member, how) in kit.items():
        dest = icons / f"{item}.png"
        img.save(dest)
        record(dest, COZY_ZIP, member, how)
    for item, src in (("rusty_sword", "Tools/Sword-01"), ("rusty_pickaxe", "Tools/Pickaxe-02"), ("rusty_axe", "Tools/Axe-02")):
        member = f"16x16 Survival RPG Icons/{src}.png"
        img = tint(Image.open(io.BytesIO(iz.read(member))).convert("RGBA"), (140, 70, 30), 0.45)
        dest = icons / f"{item}.png"
        img.save(dest)
        record(dest, ICON_ZIP, member, "tinted rust-brown 45%")
    # blood: Kenney splats shrunk to 16 px pixel art (alpha cut at half) and tinted dark red
    fx = OUT / "fx"
    fx.mkdir(parents=True, exist_ok=True)
    splat_zip = AssetZip(SPLAT_ZIP)
    for i, n in enumerate(BLOOD_SPLATS):
        member = f"PNG/Default (256px)/splat{n:02d}.png"
        src = Image.open(io.BytesIO(splat_zip.read(member))).convert("RGBA").resize((16, 16), Image.LANCZOS)
        out = Image.new("RGBA", (16, 16))
        for y in range(16):
            for x in range(16):
                if src.getpixel((x, y))[3] >= 128:
                    inner = all(0 <= x + dx < 16 and 0 <= y + dy < 16 and src.getpixel((x + dx, y + dy))[3] >= 128
                                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                    out.putpixel((x, y), (112, 14, 16, 255) if inner else (78, 8, 12, 255))
        dest = fx / f"blood_{i}.png"
        out.save(dest)
        record(dest, SPLAT_ZIP, member, "resized to 16 px, alpha cut at 50%, dark red with a darker edge")
    # GP-BANDIT-CAMP-ART (owner, 2026-10-24): the owner's animated campfire, drawn at the bandit camp (CampfireSprite). The
    # sheet is one row of 24 frames of 640 x 640 drawn on a 10 px grid: box-reduced by 10 (every 10 x 10 block is one colour,
    # so the reduction is exact) to 64 x 64 frames, alpha cut at half; nothing else changed
    member = CAMPFIRE_SHEET.split("/", 1)[1]
    src = Image.open(REPO / CAMPFIRE_SHEET).convert("RGBA")
    small = src.resize((src.width // 10, src.height // 10), Image.BOX)
    small.putalpha(small.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
    dest = fx / "campfire.png"
    small.save(dest)
    record(dest, CAMPFIRE_SHEET.split("/", 1)[0], member, "box-reduced by 10 to 24 frames of 64 x 64 (exact: drawn on a 10 px grid), alpha cut at 50%")
    # the app icon: the owner's pictures, copied unchanged; a plain dark background for the adaptive icon
    icon_dir = OUT / "icon"
    icon_dir.mkdir(parents=True, exist_ok=True)
    icon_zip = AssetZip(APP_ICON_ZIP)
    for size in (192, 432, 512):
        member = f"My_Medieval_Life_{size}x{size}.png"
        dest = icon_dir / f"icon_{size}.png"
        dest.write_bytes(icon_zip.read(member))
        record(dest, APP_ICON_ZIP, member, "copied unchanged")
    # the Windows .exe icon (owner: the approved artwork, not Godot's): every size Windows shows, made
    # from the pack's 256 px picture; embedded by the Windows export (application/icon)
    dest = icon_dir / "icon.ico"
    Image.open(io.BytesIO(icon_zip.read("My_Medieval_Life_256x256.png"))).convert("RGBA").save(
        dest, format="ICO", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    record(dest, APP_ICON_ZIP, "My_Medieval_Life_256x256.png", "saved as a Windows icon (16-256 px)")
    dest = icon_dir / "icon_background_432.png"
    Image.new("RGBA", (432, 432), (34, 24, 16, 255)).save(dest)
    prov.append({"file": str(dest.relative_to(REPO / "game")), "source": "", "member": "",
                 "transform": "generated: solid dark brown 432 px background for the Android adaptive icon", "sha256": sha(dest)})
    _import_ui(record)
    for name, rel in sorted(HUD_ICONS.items()):
        member = f"16x16 Survival RPG Icons/{rel}.png"
        dest = OUT / "ui" / f"{name}.png"
        dest.write_bytes(iz.read(member))
        record(dest, ICON_ZIP, member, "copied unchanged (a HUD status icon)")
    _import_markers(record, iz)
    _import_inventory(record, iz)
    prompts = OUT / "prompts"
    prompts.mkdir(parents=True, exist_ok=True)
    pz = AssetZip(PROMPT_ZIP)
    for name, member in sorted(PROMPTS.items()):
        dest = prompts / f"{name}.png"
        dest.write_bytes(pz.read(member))
        record(dest, PROMPT_ZIP, member, "copied unchanged")
    living_forest.import_into(prov, record)           # the trees: from the private package if it is there, else kept as they are
    craftpix_plants.import_into(prov, record)         # fruit trees (B14): from the private Craftpix zip, else kept as they are
    animal_farm.import_into(prov, record)             # the horse (B14-11): from the private Animal Farm pack, else kept as it is
    terrain_art.import_into(prov, record)             # B14-07: steps, stairs and walkways; the nails and mallet icons
    game_audio.import_into(prov, record)              # MUSIC-18, SFX-18: Ogg Vorbis music (Android) and the Cozy RPG SFX, from private-assets/ and the release WAVs
    (OUT / "PROVENANCE.json").write_text(json.dumps({"format": "mml-provenance/1", "files": prov}, indent=1) + "\n")
    print(f"imported {len(prov)} files into game/assets")


if __name__ == "__main__":
    main()
