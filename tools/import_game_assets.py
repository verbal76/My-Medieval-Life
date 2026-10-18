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
    game/assets/animals/<species>.png                CozyFarm_full_version.zip (livestock, bunnies) and
                                                     PunyMonsters.zip (boars)
    game/assets/characters/player_<s><n>_<outfit>.png player looks for character creation (listed in
                                                     game/data/appearances.json)
    game/assets/fx/blood_N.png                       kenney_splatpack.zip, shrunk and tinted dark red
    game/assets/icon/icon_<size>.png                 My_Medieval_Life_Icon_Pack.zip (the app icon)
    game/assets/ui/<name>.png                        Flat Game UI Icon Pack/ (icon tiles, the button tile)
    game/assets/ui/inventory_*.png, tab_*.png        CozyFarm_full_version.zip (the pack window, its tabs and
                                                     bag icon) and tab icons from the Assorted and Survival packs
    game/assets/prompts/<name>.png                   kenney_input-prompts_1.5.zip (keys, pad buttons, touch)
    game/assets/trees/*, icons/oak_sapling.png, icons/pine_sapling.png
                                                     the Living Forest package in private-assets/ (not in the
                                                     repository), by tools/living_forest.py (skipped, files kept,
                                                     if the package is missing)
    game/assets/PROVENANCE.json                      source, path and transformation of every file

Character sheets are 29 x 8 frames of 32 px: rows are the 8 directions (S, SE, E, NE, N, NW, W,
SW), columns as listed in tools/puny_chargen.py ANIMS.

Cozy Farm animal sheets are 4 frames x 5 rows (down, up, left, right, sleep), square frames of the size
in the pack's info.txt; Puny Monsters sheets are 12 x 8 frames of 32 px in the Puny direction order.

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
import living_forest

OUT = REPO / "game" / "assets"
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
UI_GLYPH_BROWN = (111, 74, 44)    # the same wood brown as the buttons
UI_GLYPH_EDGE = (246, 236, 214)   # the interface's cream text colour
UI_TILE = 128          # icon tiles are saved at this size
UI_WOOD = (111, 74, 44)  # the pack's navy recoloured to a wood brown (owner, 2026-10-18)
PROMPT_ZIP = "kenney_input-prompts_1.5.zip"
# input prompt icons shown with prompts and on the controls list: name -> member (128 px "Double" set)
PROMPTS = {name: f"Keyboard & Mouse/Double/{name}.png" for name in
           ["keyboard_b", "keyboard_e", "keyboard_f", "keyboard_i", "keyboard_l", "keyboard_space", "keyboard_escape",
            "keyboard_w", "keyboard_a", "keyboard_s", "keyboard_d", "keyboard_c", "keyboard_m", "keyboard_g", "mouse_left", "mouse_right",
            "mouse_scroll", "mouse_move"]}
PROMPTS.update({name: f"Xbox Series/Double/{name}.png" for name in
                ["xbox_button_a", "xbox_button_b", "xbox_button_x", "xbox_button_y", "xbox_button_view",
                 "xbox_button_menu", "xbox_stick_l", "xbox_stick_r", "xbox_stick_r_press", "xbox_lb", "xbox_rb", "xbox_dpad_down", "xbox_lt", "xbox_rt"]})
PROMPTS.update({name: f"Touch/Double/{name}.png" for name in ["touch_tap", "touch_finger_one", "touch_zoom_in",
                                                                "touch_swipe_two_move"]})
MONSTER_ZIP = "PunyMonsters.zip"
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
    "boar": (MONSTER_ZIP, "PunyMonsters/Brown-Boar-32x32.png"),
    "boar_grey": (MONSTER_ZIP, "PunyMonsters/Dirty-Gray-Boar-32x32.png"),
}
# item id -> icon file in the survival pack (variant numbers chosen for the metal or colour)
ICONS = {
    "copper_ore": "Metal/Metal-Ore-01", "iron_ore": "Metal/Metal-Ore-02", "gold_ore": "Metal/Metal-Ore-08",
    "coal": "Stone/Coal-01", "stone": "Stone/Rock-Chunk-01", "log": "Wood/Wood-Log-01",
    "plank": "Wood/Wooden-Planks-01", "wheat": "Plants & Alchemy/Herb-Bundle-01",
    "pottage": "Metal/Metal-Pot-01", "roast_meat": "Food/Steak-01", "ale": "Liquid/Brew-01",
    "meat": "Food/Meat-01", "hide": "Textile/Deer-Pelt-07", "leather": "Textile/Leather-Fabric-07",
    "iron_bar": "Metal/Metal-Ingot-02", "copper_bar": "Metal/Metal-Ingot-01", "gold_bar": "Metal/Metal-Ingot-08",
    "pickaxe": "Tools/Pickaxe-02", "axe": "Tools/Axe-02", "iron_sword": "Tools/Sword-02",
    "copper_sword": "Tools/Sword-01", "leather_armor": "Armour/Leather-Jacket-08",
    "iron_armor": "Armour/Metal-Chestplate-02", "coins": "Metal/Metail-Coins-08",
    "hammer": "Tools/Hammer-02", "fireball": "Tools/Magic-Staff-05",
    "leather_cap": "Armour/Leather-Cap-07", "iron_helmet": "Armour/Metal-Helm-05",
    # wild plants (B8-015/B8-016): yellow flower, red and blue berries, the flower tonic
    "flower": "Plants & Alchemy/Flower-09", "red_berries": "Plants & Alchemy/Berry-05",
    "blueberries": "Plants & Alchemy/Berry-16", "herbal_tonic": "Plants & Alchemy/Herbal-Potion-01",
}
JEWELRY_ZIP = "16x16 Jewelry RPG Icons.zip"
# item id -> icon in the jewelry pack (plain metals; the amulet has a red stone)
JEWELRY = {"copper_ring": "Rings/Ring-01", "gold_ring": "Rings/Ring-16", "amulet": "Necklaces/Necklace-05"}
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
                looks.append({"id": name, "sex": sex, "face": i, "outfit": outfit, "sprite": f"res://assets/characters/{name}.png"})
    (REPO / "game" / "data" / "appearances.json").write_text(json.dumps({"format": "mml-appearances/1", "looks": looks}, indent=1) + "\n")
    icons = OUT / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    iz = AssetZip(ICON_ZIP)
    for item, rel in sorted(ICONS.items()):
        member = f"16x16 Survival RPG Icons/{rel}.png"
        dest = icons / f"{item}.png"
        dest.write_bytes(iz.read(member))
        record(dest, ICON_ZIP, member, "copied unchanged")
    jz = AssetZip(JEWELRY_ZIP)
    for item, rel in sorted(JEWELRY.items()):
        member = f"16x16 Jewelry RPG Icons/{rel}.png"
        dest = icons / f"{item}.png"
        dest.write_bytes(jz.read(member))
        record(dest, JEWELRY_ZIP, member, "copied unchanged")
    member = "full version/tiles/tiles.png"
    (tiles / "cozyfarm-tiles.png").write_bytes(AssetZip(COZY_ZIP).read(member))
    record(tiles / "cozyfarm-tiles.png", COZY_ZIP, member, "copied unchanged")
    animals = OUT / "animals"
    animals.mkdir(parents=True, exist_ok=True)
    for species, (zname, member) in sorted(ANIMALS.items()):
        dest = animals / f"{species}.png"
        dest.write_bytes(AssetZip(zname).read(member))
        record(dest, zname, member, "copied unchanged")
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
    for item, src in (("rusty_sword", "Tools/Sword-01"), ("rusty_pickaxe", "Tools/Pickaxe-02")):
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
    (OUT / "PROVENANCE.json").write_text(json.dumps({"format": "mml-provenance/1", "files": prov}, indent=1) + "\n")
    print(f"imported {len(prov)} files into game/assets")


if __name__ == "__main__":
    main()
