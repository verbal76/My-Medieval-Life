"""Sprite package for Aseprite (register entry B14-12): pixel-grid copies of every missing or weak sprite.

docs/assets/SPRITE_NEEDS.md lists each sprite the game needs but lacks, or draws with a weak stand-in, and
why (found in the code and the provenance, not guessed). This tool makes, for each entry of ENTRIES:

    out/sprite_package/<category>__<id>.png      the grid copy: the current art ("now", if any) beside an empty
                                                 canvas of the size the game needs ("draw here"), every source
                                                 pixel a cell, a strong line round each frame (sheets.contact)
    out/sprite_package/<category>__<id>_1x.png   the canvas at the game's real size, to edit in Aseprite: the
                                                 current art in its first frame where there is any, else empty

and out/sprite_package.zip (the folder plus a copy of SPRITE_NEEDS.md). Reads game/assets and the village map
data only; writes only under out/ (git-ignored: CLAUDE.md section 3). Standard library + Pillow.

    python3 tools/assets/sprite_package.py
"""
import json
import shutil
import sys
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sheets  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
GAME = REPO / "game"
OUT = REPO / "out" / "sprite_package"
DOC = REPO / "docs" / "assets" / "SPRITE_NEEDS.md"
T = 16
PAID_COLS = 220                      # punyworld-tiles.png is 220 tiles wide (village.json atlas 0)


# ---------------------------------------------------------------- sources ------------------------------------
def asset(rel):
    return Image.open(GAME / "assets" / rel).convert("RGBA")


_atlas = None


def tile(t):
    """One 16 px tile of the paid Puny World atlas (village.json atlas 0)."""
    global _atlas
    if _atlas is None:
        _atlas = asset("tiles/punyworld-tiles.png")
    x, y = (t % PAID_COLS) * T, (t // PAID_COLS) * T
    return _atlas.crop((x, y, x + T, y + T))


def tiles(rows):
    """Tiles laid out as rows of ids (None = empty cell)."""
    img = Image.new("RGBA", (len(rows[0]) * T, len(rows) * T), (0, 0, 0, 0))
    for j, row in enumerate(rows):
        for i, t in enumerate(row):
            if t is not None:
                img.alpha_composite(tile(t), (i * T, j * T))
    return img


_village = None


def village_cells(pairs, size):
    """The workshop paste: (local cell, village cell) pairs drawn from village.json's below layers, as
    tools/build_village.py WORKSHOPS copies them, on a canvas of `size` cells."""
    global _village
    if _village is None:
        _village = json.loads((GAME / "data" / "village.json").read_text())
    d = _village
    img = Image.new("RGBA", (size[0] * T, size[1] * T), (0, 0, 0, 0))
    x0 = min(p[0][0] for p in pairs)
    y0 = min(p[0][1] for p in pairs)
    for (lx, ly), (vx, vy) in pairs:
        for lay in d["layers"]:
            if not lay["name"].startswith("below"):
                continue
            v = lay["data"][vy * d["w"] + vx]
            if v >= 0 and v // 100000 == 0:
                img.alpha_composite(tile(v % 100000), ((lx - x0) * T, (ly - y0) * T))
    return img


def frames(sheet, cols, rows, cw=32, ch=32):
    """Columns `cols` of rows `rows` of a sheet, side by side / stacked in that order."""
    img = Image.new("RGBA", (len(cols) * cw, len(rows) * ch), (0, 0, 0, 0))
    for j, r in enumerate(rows):
        for i, c in enumerate(cols):
            img.paste(sheet.crop((c * cw, r * ch, c * cw + cw, r * ch + ch)), (i * cw, j * ch))
    return img


def half(img, factor=0.5):
    """What the game draws for a scaled sprite (Sprite2D.scale with nearest filtering), approximately."""
    return img.resize((max(1, round(img.width * factor)), max(1, round(img.height * factor))), Image.NEAREST)


# ---------------------------------------------------------------- stand-ins drawn in code -------------------
def sit_now():
    """ActorSprite.sit: the idle frame cut at the knees (the shader drops local y > -4: frame rows from 20)."""
    f = frames(asset("characters/player_m3_basic.png"), [0], [0, 2, 4, 6])
    out = Image.new("RGBA", (4 * 32, 32), (0, 0, 0, 0))
    for i in range(4):
        cell = f.crop((0, i * 32, 32, i * 32 + 32))
        ImageDraw.Draw(cell).rectangle((0, 20, 31, 31), fill=(0, 0, 0, 0))
        out.paste(cell, (i * 32, 0))
    return out


def small_boulder_now():
    """MapView._add_small_boulder: the boulder tile shrunk 16 -> 10 px (nearest) on the cell's bottom."""
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    img.alpha_composite(tile(1964).resize((10, 10), Image.NEAREST), (3, T - 10))
    return img


def target_now():
    """main.gd target_marker: the iron sword icon turned 225 degrees and scaled 1.5."""
    s = asset("icons/iron_sword.png").rotate(-225, resample=Image.NEAREST, expand=True)
    return s.resize((round(s.width * 1.5), round(s.height * 1.5)), Image.NEAREST)


def lock_now():
    """InventoryWindow._draw_lock, in art pixels on the 18 px cell."""
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((1, 1, 16, 16), fill=(51, 33, 20, 140))
    c, hi = (70, 50, 36, 255), (150, 120, 80, 255)
    d.rectangle((6, 4, 11, 5), fill=c)
    d.rectangle((6, 4, 6, 8), fill=c)
    d.rectangle((11, 4, 11, 8), fill=c)
    d.rectangle((5, 8, 12, 13), fill=c)
    d.rectangle((6, 9, 11, 9), fill=hi)
    d.rectangle((8, 10, 9, 11), fill=(30, 20, 14, 255))
    return img


def hp_bar_now():
    """main.gd HpBar: two ColorRects, 16 x 2, dark back and red fill (shown here at 60%)."""
    img = Image.new("RGBA", (16, 2), (38, 26, 20, 255))
    ImageDraw.Draw(img).rectangle((0, 0, 9, 1), fill=(217, 38, 38, 255))
    return img


def sign_now():
    """main.gd _sync_signs: a Label on a flat brown box (no art); the box colours on a 24 x 9 canvas."""
    img = Image.new("RGBA", (24, 9), (110, 74, 43, 255))
    ImageDraw.Draw(img).rectangle((0, 0, 23, 8), outline=(64, 41, 23, 255))
    return img


def slots_now():
    """The six equipment-slot glyphs (128 px) as the inventory draws them, in a 14 px square (nearest here)."""
    names = ["weapon", "tool", "armor", "head", "amulet", "ring"]
    img = Image.new("RGBA", (14 * 6, 14), (0, 0, 0, 0))
    for i, n in enumerate(names):
        img.alpha_composite(asset("ui/slot_%s.png" % n).resize((14, 14), Image.NEAREST), (i * 14, 0))
    return img


def crop_sets():
    """The wheat field edge sets every crop is drawn with (village.json tiles.field: growing 1747, ripe 2627)."""
    img = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    for k, base in enumerate((1747, 2627)):
        img.alpha_composite(tiles([[base + r * PAID_COLS + c for c in range(4)] for r in range(4)]), (k * 64, 0))
    return img


def cart_now():
    return tile(3009)


# ---------------------------------------------------------------- the entries -------------------------------
# (category, id, now() or None, needed canvas (w, h), frame cell (w, h), zoom[, options]). Options: now_cell (the
# frame of the "now" art when it differs: half-scale stand-ins), start() (the 1x canvas to edit, when it is not
# the needed canvas with the current art in its first frame: a baby or a child is drawn over the adult sheet),
# caption (for "now"). The text is in SPRITE_NEEDS.md.
def _icon(name):
    return lambda: asset("icons/%s.png" % name)


ENTRIES = [
    # characters
    ("characters", "tool_swing", lambda: frames(asset("characters/player_m3_basic.png"), [16, 17, 18], range(8)), (96, 256), (32, 32), 6),
    ("characters", "child", lambda: half(asset("characters/villager_00.png")), (928, 256), (32, 32), 4,
     {"now_cell": (16, 16), "start": lambda: asset("characters/villager_00.png")}),
    ("characters", "sit", sit_now, (128, 32), (32, 32), 8),
]
for skin, frame in [("mini_bunny", 32), ("boar", 32), ("boar_grey", 32), ("mini_boar", 32), ("mini_doe", 32),
                    ("mini_stag", 32), ("mini_fox", 32), ("mini_wolf", 32), ("mini_bird", 16), ("mini_bear", 32)]:
    ENTRIES.append(("animals", skin + "_baby", (lambda s=skin: half(asset("animals/%s.png" % s))),
                    asset("animals/%s.png" % skin).size, (frame, frame), 4,
                    {"now_cell": (frame // 2, frame // 2), "start": (lambda s=skin: asset("animals/%s.png" % s))}))
for name in ["bread", "pottage", "plain_clothes", "handcart", "cart_wheel", "cart_axle", "cart_ironwork", "feather",
             "padlock", "lockpick", "plough", "linen_bandage", "herbal_poultice", "oak_sapling", "pine_sapling",
             "rotten_apple", "rusty_sword", "rusty_pickaxe"]:
    ENTRIES.append(("items", name, _icon(name), (16, 16), (16, 16), 16))
ENTRIES += [
    ("buildings", "handcart_world", cart_now, (72, 24), (24, 24), 10),
    ("buildings", "storefront_counter", lambda: tiles([[1890, 3502]]), (32, 16), (16, 16), 12),
    ("buildings", "fit_anvil", lambda: tile(2540), (16, 16), (16, 16), 16),
    ("buildings", "fit_forge", lambda: tile(2567), (16, 16), (16, 16), 16),
    ("buildings", "fit_shelves", lambda: tile(2542), (16, 16), (16, 16), 16),
    ("buildings", "fit_counter", lambda: tile(3578), (16, 16), (16, 16), 16),
    ("buildings", "stove", lambda: village_cells([((1, 5), (51, 47)), ((2, 5), (52, 47)), ((1, 6), (53, 47))], (2, 2)), (32, 32), (16, 16), 12),
    ("buildings", "sawhorse", lambda: village_cells([((1, 6), (65, 26)), ((2, 6), (66, 26))], (2, 1)), (32, 16), (16, 16), 12),
    ("buildings", "apothecary_station", lambda: village_cells([((1, 6), (51, 47)), ((2, 6), (52, 47)), ((1, 7), (53, 47))], (2, 2)), (32, 32), (16, 16), 12),
    ("buildings", "stall_display", None, (16, 16), (16, 16), 16),
    ("terrain", "crop_carrot", crop_sets, (128, 64), (64, 64), 6),
    ("terrain", "crop_potato", crop_sets, (128, 64), (64, 64), 6),
    ("terrain", "crop_herb", crop_sets, (128, 64), (64, 64), 6),
    ("terrain", "loot_pile", _icon("meat"), (16, 16), (16, 16), 16),
    ("terrain", "small_boulder", small_boulder_now, (16, 16), (16, 16), 16),
    ("effects", "fireball", _icon("fireball"), (64, 16), (16, 16), 10),
    ("effects", "target_marker", target_now, (32, 16), (16, 16), 10, {"start": lambda: Image.new("RGBA", (32, 16), (0, 0, 0, 0))}),
    ("ui", "equipment_slots", slots_now, (84, 14), (14, 14), 12, {"caption": "now (approximately: 128 px glyphs in 14 px)"}),
    ("ui", "skill_trading", lambda: asset("ui/skill_trading.png"), (128, 128), (128, 128), 4),
    ("ui", "locked_cell", lock_now, (18, 18), (18, 18), 16),
    ("ui", "house_sign", sign_now, (24, 9), (24, 9), 12),
    ("ui", "enemy_hp_bar", hp_bar_now, (16, 4), (16, 4), 16),
]


# ---------------------------------------------------------------- drawing -----------------------------------
BG = (52, 56, 64, 255)
INK = (240, 240, 240, 255)


def grid_copy(now, need, cell, zoom, now_cell=None, caption="now (what the game draws)"):
    """'now' (the current art, any size) beside 'draw here' (an empty canvas of the needed size), both as
    sheets.contact grids at the same zoom, each under a caption."""
    parts = []
    if now is not None:
        c = now_cell or cell
        cw, ch = (c if now.width % c[0] == 0 and now.height % c[1] == 0 else now.size)
        parts.append((caption, sheets.contact(now, cw, ch, zoom)))
    parts.append(("draw here: %d x %d px, frames %d x %d" % (need[0], need[1], cell[0], cell[1]),
                  sheets.contact(Image.new("RGBA", need, (0, 0, 0, 0)), cell[0], cell[1], zoom)))
    gap, top = 24, 18
    w = sum(p[1].width for p in parts) + gap * (len(parts) + 1)
    h = max(p[1].height for p in parts) + top + gap
    out = Image.new("RGBA", (max(w, 260), h), BG)
    d = ImageDraw.Draw(out)
    x = gap
    for caption, img in parts:
        d.text((x, 4), caption, fill=INK)
        out.paste(img, (x, top))
        x += img.width + gap
    return out


def one_x(now, need):
    """The canvas to edit: the needed size, the current art in its top-left frame where it fits."""
    img = Image.new("RGBA", need, (0, 0, 0, 0))
    if now is not None:
        img.alpha_composite(now.crop((0, 0, min(now.width, need[0]), min(now.height, need[1]))), (0, 0))
    return img


def build(out=OUT):
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    names = []
    for cat, ident, now_fn, need, cell, zoom, *rest in ENTRIES:
        opt = rest[0] if rest else {}
        now = now_fn() if now_fn else None
        stem = "%s__%s" % (cat, ident)
        grid_copy(now, need, cell, zoom, opt.get("now_cell"), opt.get("caption", "now (what the game draws)")).save(out / (stem + ".png"))
        (opt["start"]() if "start" in opt else one_x(now, need)).save(out / (stem + "_1x.png"))
        names.append(stem)
    if DOC.exists():
        shutil.copy(DOC, out / DOC.name)
    z = out.parent / "sprite_package.zip"
    with zipfile.ZipFile(z, "w", zipfile.ZIP_DEFLATED) as zf:
        for p in sorted(out.iterdir()):
            zf.write(p, "sprite_package/" + p.name)
    return names, z


def main():
    names, z = build()
    print("%d entries, %d files in %s" % (len(names), len(names) * 2, OUT.relative_to(REPO)))
    print("wrote", z.relative_to(REPO))


if __name__ == "__main__":
    main()
