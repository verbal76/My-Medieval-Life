"""Import Szadi's Fantasy Lands Houses (demo) as the region's southern house style and the towns' elite houses (B25R1-022).

Owner, 2026-11-04 (register B25R1-022): drawn at 32 px, halve to our 16 px; "If the pallet is too dark, modify the coloring
on it to match what we have and we're going to have to make the roofs removable like our current ones for going inside";
"we don't have to mix these into the villages that already exist. Unless we want to do like some upscale housing for the
elites. But we could also do whole homesteads and villages in this style for different regions".

CLAUDE.md section 3 (private asset workflow): the zip lives in `private-assets/` (its licence allows use and modification in a
commercial game, not reselling the asset itself). This step reads it in place and writes only the game's copies:

    game/assets/tiles/fl_houses.png    the houses' outsides, halved and recoloured, cut into 16 px tiles (16 columns): MapView
                                       atlas 11, tile value 1100000 + row * 16 + column
    game/data/style_stamps.json        building stamps (mml-style-stamps/1) of each house fitted to each footprint the region's
                                       settlement plan lays out (house_7 ... manor), so a slot keeps its rect and door and only
                                       what is drawn and solid changes

How each house is made, nothing drawn new:
  1. cut from Exterrior/ready_to_use_houses.png (DESIGNS: its box, door centre and wall base, measured on the halved art);
  2. halved: 2 x 2 area average with premultiplied alpha, alpha cut at half (ASSET_SCALING_STANDARD: integer 1/2, box);
  3. recoloured toward the Puny World houses: value v -> v ** GAMMA, saturation x SAT, hue kept (the pack reads about a third
     darker and greyer than our art; judged side by side at normal zoom);
  4. placed in the footprint so its door fills the footprint's door cell and its wall base sits on that cell's bottom edge;
  5. its outside (every pixel down to the wall base) is the roof layer above3 (the village's roof layers fade as one); the
     ground skirt below the base (grass, cobbles, barrels) is below5, under the characters;
  6. the inside is laid with the Puny World interior kit the village's houses use (walls, floor, door, bed, table, chest) in
     the largest rectangle the outside covers fully round the door; solid: the outside's cells down to the base, the inside's
     floor open, the door open; nothing below the base is solid.

    python3 tools/fl_houses.py      # also run by tools/import_game_assets.py; a missing package leaves the files as they are
"""
import hashlib
import io
import json
import os
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
DEFAULT_DIR = REPO / "private-assets"
PACKAGE = "FL_Houses_Demo_v1.0.zip"
SHEET = "Exterrior/ready_to_use_houses.png"
TILES_OUT = REPO / "game" / "assets" / "tiles" / "fl_houses.png"
DATA_OUT = REPO / "game" / "data" / "style_stamps.json"
FORMAT = "mml-style-stamps/1"
ATLAS = 11
COLS = 16
GAMMA = 0.75
SAT = 1.25
T = 16
# name -> (box in the 32 px sheet, door centre x and wall base y in the halved house). The sheet's seventh house has no door
# on its front (windows only) and the eighth is an open shed: not houses one enters, not used.
DESIGNS = {
    "fl_shop":    ((12, 0, 223, 241), 64, 112),    # a merchant's house, the awning over its open front
    "fl_cottage": ((230, 0, 390, 247), 37, 96),    # the small brick cottage
    "fl_tall":    ((416, 0, 640, 285), 72, 128),   # the tall house with the lean-to and the banner
    "fl_barn":    ((656, 0, 842, 298), 40, 126),   # the barn-fronted farmhouse
    "fl_hall":    ((864, 0, 1254, 283), 145, 111),  # the great house: two gabled wings round a yard gate (elite)
    "fl_house":   ((1272, 0, 1442, 252), 43, 110),  # the timbered house with lean-tos
}
FOOTPRINTS = ["house", "house_7", "house_7d", "house_9", "house_9d", "house_11", "house_11d", "house_13", "manor"]
# the Puny World interior kit (as the village's house_7): walls, floor, door, furniture (atlas 0 ids)
BACK = [660, 441, 220, 220, 443]
FLOOR = [12819, 12599, 12381, 12378, 13041, 13040, 12379, 12601, 12821, 13039, 12818, 13038, 12380]
CHEST, BARREL, TABLE, BEDS, DOOR, MAT = 355, 577, 1003, [1693, 1698], 3875, 13695


def _folder():
    return Path(os.environ.get("MML_PRIVATE_ASSETS") or DEFAULT_DIR)


def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def halve(img):
    """2 x 2 area average with premultiplied alpha (no dark fringes from transparent pixels), alpha cut at half."""
    a = np.asarray(img.convert("RGBA")).astype(np.float64)
    h, w = a.shape[:2]
    a = a[: h // 2 * 2, : w // 2 * 2]
    al = a[..., 3:4] / 255.0
    pm = a[..., :3] * al

    def red(x):
        return (x[0::2, 0::2] + x[1::2, 0::2] + x[0::2, 1::2] + x[1::2, 1::2]) / 4

    rp, ra = red(pm), red(al)
    rgb = np.where(ra > 0, rp / np.maximum(ra, 1e-9), 0)
    out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    out[..., :3] = np.clip(np.round(rgb), 0, 255)
    out[..., 3] = np.where(ra[..., 0] >= 0.5, 255, 0)
    out[out[..., 3] == 0] = 0
    return Image.fromarray(out, "RGBA")


def recolour(img, gamma=GAMMA, sat=SAT):
    """Lighter and warmer, hue kept: value v -> v ** gamma, saturation x sat (clipped)."""
    a = np.asarray(img.convert("RGBA")).astype(np.float64)
    rgb = a[..., :3] / 255
    v = rgb.max(-1, keepdims=True)
    mn = rgb.min(-1, keepdims=True)
    s = np.where(v > 0, (v - mn) / np.maximum(v, 1e-9), 0)
    t = np.where(v - mn > 0, (rgb - mn) / np.maximum(v - mn, 1e-9), 0)
    v2 = v ** gamma
    s2 = np.clip(s * sat, 0, 1)
    mn2 = v2 * (1 - s2)
    o = a.copy()
    o[..., :3] = np.round(np.clip(mn2 + t * (v2 - mn2), 0, 1) * 255)
    o[o[..., 3] == 0] = 0
    return Image.fromarray(o.astype(np.uint8), "RGBA")


def houses(sheet):
    """name -> the halved, recoloured house (RGBA), from the pack's sheet."""
    out = {}
    for name, (box, _dx, _by) in DESIGNS.items():
        x0, y0, x1, y1 = box
        out[name] = recolour(halve(sheet.crop((x0, y0, x0 + (x1 - x0 + 1) // 2 * 2, y0 + (y1 - y0 + 1) // 2 * 2))))
    return out


def _footprints():
    st = dict(json.loads((REPO / "game" / "data" / "village.json").read_text())["stamps"])
    st.update(json.loads((REPO / "game" / "data" / "region_stamps.json").read_text())["stamps"])
    return {n: (int(st[n]["w"]), int(st[n]["h"]), int(st[n]["door"][0]), int(st[n]["door"][1])) for n in FOOTPRINTS}


class Atlas:
    """The tiles cut from every placed house, each distinct tile once, in the order first met."""

    def __init__(self):
        self.ids = {}
        self.tiles = []

    def id_of(self, tile):
        key = tile.tobytes()
        if key not in self.ids:
            self.ids[key] = len(self.tiles)
            self.tiles.append(tile)
        return ATLAS * 100000 + self.ids[key]

    def image(self):
        rows = (len(self.tiles) + COLS - 1) // COLS
        img = Image.new("RGBA", (COLS * T, max(1, rows) * T), (0, 0, 0, 0))
        for i, t in enumerate(self.tiles):
            img.paste(t, ((i % COLS) * T, (i // COLS) * T))
        return img


def _place(name, house, fp):
    """The house on a footprint's canvas: its door centre on the door cell's centre, its wall base on that cell's bottom
    edge. None when it does not fit."""
    w, h, dc, dr = fp
    _box, dx, base = DESIGNS[name]
    ox = dc * T + T // 2 - dx
    oy = (dr + 1) * T - base
    if ox < 0 or oy < 0 or ox + house.width > w * T:
        return None
    canvas = Image.new("RGBA", (w * T, h * T), (0, 0, 0, 0))
    canvas.paste(house.crop((0, 0, house.width, min(house.height, h * T - oy))), (ox, oy))
    return canvas


def _inside(cov, dc, dr, least=0.5):
    """The largest rectangle (at least 4 x 4 where there is one) with its bottom row on the door's row, round the door,
    whose every cell the outside covers at least half: [c0, c1] x [rt, dr]."""
    lo = hi = dc
    while lo - 1 >= 0 and cov[dr][lo - 1] >= least:
        lo -= 1
    while hi + 1 < len(cov[dr]) and cov[dr][hi + 1] >= least:
        hi += 1
    best = None
    for c0 in range(lo, dc + 1):
        for c1 in range(dc, hi + 1):
            rt = dr
            while rt - 1 >= 0 and all(cov[rt - 1][c] >= least for c in range(c0, c1 + 1)):
                rt -= 1
            fw, fh = c1 - c0 + 1, dr - rt + 1
            key = (fw >= 4 and fh >= 4, fw * fh, fh, -c0)
            if best is None or key > best[0]:
                best = (key, (c0, c1, rt))
    return best[1]


_PUNY = []


def _puny_tile(v):
    if not _PUNY:
        _PUNY.append(Image.open(REPO / "game" / "assets" / "tiles" / "punyworld-tiles.png").convert("RGBA"))
    i = int(v) % 100000
    return _PUNY[0].crop(((i % 220) * T, (i // 220) * T, (i % 220 + 1) * T, (i // 220 + 1) * T))


def _masked(v, mask):
    """An interior tile of the Puny World kit cut to the outside's shape in its cell (where the house does not cover the
    cell, the inside must not show through from outside either)."""
    tile = _puny_tile(v)
    a = np.asarray(tile).copy()
    a[..., 3] = np.where(mask, a[..., 3], 0)
    a[a[..., 3] == 0] = 0
    return Image.fromarray(a, "RGBA")


def build_stamp(name, house, fp, atlas, salt):
    w, h, dc, dr = fp
    canvas = _place(name, house, fp)
    if canvas is None:
        return None
    a = np.asarray(canvas)[..., 3] > 0
    cov = [[float(a[r * T:(r + 1) * T, c * T:(c + 1) * T].mean()) for c in range(w)] for r in range(h)]
    c0, c1, rt = _inside(cov, dc, dr)
    fw, fh = c1 - c0 + 1, dr - rt + 1
    if fw < 4 or fh < 4:
        return None
    n = w * h
    lay = {k: [-1] * n for k in ("ground1", "ground2", "below0", "below1", "below5", "above3")}
    solid = [["0"] * w for _ in range(h)]
    for r in range(h):
        for c in range(w):
            tile = canvas.crop((c * T, r * T, (c + 1) * T, (r + 1) * T))
            if tile.getbbox() is None:
                continue
            lay["above3" if r <= dr else "below5"][r * w + c] = atlas.id_of(tile)
            if r <= dr and cov[r][c] >= 0.5:
                solid[r][c] = "1"
    # the inside, in the village houses' kit: back wall top, wall face, floor, front wall with the door
    k = 0
    for y in range(fh):
        for x in range(fw):
            c, r = c0 + x, rt + y
            i = r * w + c
            k += 1
            solid[r][c] = "1"
            if y == 0:
                lay["ground1"][i] = 223 if x == 0 else 443 if x == fw - 1 else BACK[(x + salt) % len(BACK)]
            elif y == 1:
                lay["ground1"][i] = 450 if x == 0 else 449 if x == fw - 1 else 673
                lay["below0"][i] = 59 if x == 0 else 61 if x == fw - 1 else 720
            elif y < fh - 1:
                lay["ground1"][i] = 455 if x == 0 else 232 if x == fw - 1 else FLOOR[(x * 7 + y * 3 + salt) % len(FLOOR)]
                if 0 < x < fw - 1:
                    lay["below0"][i] = -1
                    solid[r][c] = "0"
                else:
                    lay["below0"][i] = 278
            else:
                lay["ground1"][i] = 230 if x == 0 else 229 if x == fw - 1 else 443 if c == dc else 14
                lay["below0"][i] = (499 if x == 0 else 501 if x == fw - 1 else -1 if c == dc else
                                    721 if c == dc - 1 else 719 if c == dc + 1 else 720)
                if c == dc:
                    lay["below1"][i] = DOOR
                    lay["ground2"][i] = MAT
                    solid[r][c] = "0"
    # furniture against the walls, never in the door's column (the way in stays open)
    floor_rows = list(range(rt + 2, dr))
    inner = [c for c in range(c0 + 1, c1) if c != dc]

    def put(c, r, v):
        if c in inner and r in floor_rows and lay["below1"][r * w + c] < 0:
            lay["below1"][r * w + c] = v
            solid[r][c] = "1"

    if inner and floor_rows:
        put(inner[0], floor_rows[0], CHEST)
        put(inner[-1], floor_rows[0], BARREL)
        bed_col = inner[0] if inner[0] != dc else inner[-1]
        for j, r in enumerate(floor_rows[1:3]):
            put(bed_col, r, BEDS[(j + salt) % 2])
        if len(inner) >= 3 and len(floor_rows) >= 3:
            put(inner[len(inner) // 2], floor_rows[len(floor_rows) // 2], TABLE)
    # the way in: from the door up into the room, kept open
    for r in floor_rows:
        if lay["below1"][r * w + dc] < 0:
            solid[r][dc] = "0"
    # inside tiles in a cell the outside covers only in part: cut to its shape (new atlas tiles), so nothing shows round it
    for key in ("ground1", "ground2", "below0", "below1"):
        for i, v in enumerate(lay[key]):
            r, c = divmod(i, w)
            if v >= 0 and cov[r][c] < 1.0:
                lay[key][i] = atlas.id_of(_masked(v, a[r * T:(r + 1) * T, c * T:(c + 1) * T]))
    out = {"w": w, "h": h, "door": [dc, dr], "layers": {k: v for k, v in lay.items() if any(t >= 0 for t in v)},
           "solid": ["".join(row) for row in solid], "inside": [c0, rt, fw, fh], "design": name}
    return out


def build(sheet):
    """(atlas image, style_stamps document) from the pack's sheet."""
    hs = houses(sheet)
    fps = _footprints()
    atlas = Atlas()
    stamps = {}
    fits = {}
    for fn in FOOTPRINTS:
        for k, name in enumerate(DESIGNS):
            st = build_stamp(name, hs[name], fps[fn], atlas, k)
            if st is None:
                continue
            sn = "%s@%s" % (name, fn)
            stamps[sn] = st
            fits.setdefault(fn, []).append(sn)
    doc = {"format": FORMAT, "atlas": ATLAS,
           "_note": "made by tools/fl_houses.py from Szadi's Fantasy Lands Houses (B25R1-022); a house fitted to each footprint",
           "styles": {"fl": {"name": "southern timber and brick", "homes": {f: [s for s in fits.get(f, []) if not s.startswith("fl_hall")]
                                                                          for f in FOOTPRINTS if f != "manor"},
                             "elite": {f: [s for s in fits.get(f, []) if s.startswith("fl_hall")] or fits.get(f, []) for f in fits}}},
           "stamps": stamps}
    return atlas.image(), doc


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py. Returns the number of files written."""
    zp = _folder() / PACKAGE
    if not zp.is_file():
        print("%s not found (MML_PRIVATE_ASSETS or %s): FL houses import skipped; files are left as they are" % (PACKAGE, DEFAULT_DIR))
        old = REPO / "game" / "assets" / "PROVENANCE.json"
        if old.exists():
            prov.extend(e for e in json.loads(old.read_text())["files"] if e.get("source") == PACKAGE)
        return 0
    with zipfile.ZipFile(zp) as z:
        sheet = Image.open(io.BytesIO(z.read(SHEET))).convert("RGBA")
    assert sheet.size == (1824, 320), sheet.size
    img, doc = build(sheet)
    TILES_OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(TILES_OUT)
    record(TILES_OUT, PACKAGE, SHEET, "six houses halved (2x2 area average, premultiplied alpha, alpha cut at half), recoloured "
           "(value ** %.2f, saturation x %.2f, hue kept), placed on the region's house footprints and cut into 16 px tiles, each "
           "distinct tile once (MapView atlas %d, %d columns); the stamps are game/data/style_stamps.json" % (GAMMA, SAT, ATLAS, COLS))
    DATA_OUT.write_text(json.dumps(doc, separators=(",", ":")) + "\n")
    return 1


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    prov = [e for e in doc["files"] if e.get("source") != PACKAGE]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member,
                     "transform": how, "sha256": _sha(dest)})

    print("imported %d sheets" % import_into(prov, record))
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")


if __name__ == "__main__":
    main()
