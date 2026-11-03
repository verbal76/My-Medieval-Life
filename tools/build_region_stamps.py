"""Write game/data/region_stamps.json: colour variants of the village's building stamps for the region's settlements.

B25R1-018 phase 3 (owner directive 2026-11-03: the settlements "should not be rows of identical houses"). Shade's Puny World
(paid) tileset draws its roof and wall kit in colour blocks laid out alike, so the same roof in another colour is the same
tile some rows further down the sheet, with the same shape (alpha mask) and other colours. For each variant, this tool maps
every tile of a stamp to its counterpart at the variant's offset when the two tiles have the same mask, and keeps the tile
otherwise (furniture, doors, plants). Nothing is drawn new: the art is the tileset the game already imports.

Variants are kept only where the whole roof maps cleanly (checked by eye in a contact image; see VARIANTS). The others in
the sheet (blue, red, teal, olive, grey) are laid out with other offsets and map only in part, so they are not used yet.

Run:  python3 tools/build_region_stamps.py
"""

import json

import numpy as np
from PIL import Image

from assetzip import REPO, AssetZip

OUT = REPO / "game" / "data" / "region_stamps.json"
VILLAGE = REPO / "game" / "data" / "village.json"
TILES = REPO / "game" / "assets" / "tiles" / "punyworld-tiles.png"
COLS = 220
FORMAT = "mml-region-stamps/1"
# variant name -> (tile offset in the paid atlas, stamps it applies to). "thatch": the straw roof, 16 rows below the tiled one.
VARIANTS = {"thatch": (16 * COLS, ["house"])}


PAID = "PUNY-WORLD-PAID_v1.zip"
CASTLE = "PUNY-WORLD-PAID_v1/Tiled/sample-castle-1.tmj"
# --- civic art (B25R1-018 phase 3, owner directive 2026-11-03: Higham's walls, white castle, abbey and towers; Wulstead's
# fountain and buttercross; Netherton's church). Everything is cut from Shade's Puny World (paid) as the game's houses are.
# The wall kit: the battlemented wall of the castle sample, read from its Walls layer (sample cells, not guessed ids):
#   a wall running east-west is 9 rows deep (merlons, a three-row walkway, the parapet, a four-row stone face), here its
#   first 8 columns, which repeat; one running north-south is 5 columns wide (parapet, walkway, parapet), 4 rows repeating;
#   the face's east end is the column where the sample's wall turns north.
WALL_H = (0, 18, 8, 9)            # x, y, w, h in the sample
WALL_V = (12, 14, 5, 4)
WALL_END = (16, 22, 1, 5)          # parapet and face at the east end
BANNER = (3, 17)                   # a two-tile banner on the castle wall (Object layer), hung on the parapet and face
# The white castle (BONE-C5-P002 "a white castle on a knoll"): its stone faces in the sheet's light grey brick (the wall kit
# Shade draws inside houses: top, middle, middle, base rows, columns 59-60), against the dark face of the town walls; the
# battlements and walkway stay the kit's. Grey face tile -> light face tile by its place in the face's 4 x 4 block.
PALE = [[3139, 3140, 3139, 3140], [3359, 3360, 3359, 3360], [3799, 3800, 3799, 3800], [3579, 3580, 3579, 3580]]
WINDOW = 3662                      # the shuttered window of Shade's timber fronts, set into a church's stone face
# The slate hall (the manor of the village sample, sample-village-2 Roof layer): a gable roof with its ridge running
# north-south, any length and odd width; its front a stone face (the castle kit's face) with the wooden door.
SLATE = {"top": [20762, 20763, 20764, 20765, 21422, 20767, 20768, 20769, 20770], "left": 20982, "right": 20990, "ridge": 21642,
         "slope_l": [20102, 20542, 20104, 20323, 20322, 20324, 20103, 20543, 20544], "slope_r": [20108, 20548, 20110, 20109, 20550, 20328],
         "end": [22962, 21862, 22970], "eaves": [20771, 20772, 20773, 20774, 20775, 20776, 20777, 20778, 20779]}
FACE = [[910, 911, 912, 913], [1130, 1131, 1132, 1133], [1350, 1351, 1352, 1353], [1570, 1571, 1572, 1573]]
DOOR = 3875
ARCADE = [4019, 4020, 4021]        # a round-arched stone arcade (left, middle, right)
FOUNTAIN = [[3225, 3226], [3445, 3446]]   # the round stone basin
# a grave-mound of the ancient folk (BONE-C4-P009): Cozy Farm's 3 x 3 patch of rough turf (atlas offset 200000), walked over
BARROW = [[200000, 200001, 200002], [200054, 200055, 200056], [200108, 200109, 200110]]


def _layers(paid, name):
    d = json.loads(paid.text(name))
    out = {}

    def walk(ls, p=""):
        for l in ls:
            if l["type"] == "group":
                walk(l["layers"], p + l["name"] + "/")
            elif l["type"] == "tilelayer":
                out[p + l["name"]] = [((v & 0x1FFFFFFF) - 1) if v else -1 for v in l["data"]]
    walk(d["layers"])
    return out


def _cut(layer, rect):
    x0, y0, w, h = rect
    return [[layer[(y0 + y) * 30 + x0 + x] for x in range(w)] for y in range(h)]


def _pick(pool, i, j, salt):
    return pool[((i * 73856093) ^ (j * 19349663) ^ salt) % len(pool)]


def slate_hall(w, rows, front, door=True, arcade=False, pale=False, windows=False):
    """A slate-roofed stone building w (odd, >= 7) wide: `rows` of roof (ridge north-south), then `front` rows of stone face
    with the door in the middle of the bottom one, or an open arcade (a buttercross). Layers: the roof and front in above3
    (over the characters, as a house's), solid but for the door."""
    half = (w - 1) // 2
    top = SLATE["top"]
    grid = [[top[0], top[1]] + [top[2]] * (half - 3) + [top[3], top[4], top[5]] + [top[6]] * (half - 3) + [top[7], top[8]]]
    for j in range(1, rows - 2):
        grid.append([SLATE["left"]] + [_pick(SLATE["slope_l"], i, j, 1) for i in range(half - 1)] + [SLATE["ridge"]]
                    + [_pick(SLATE["slope_r"], i, j, 2) for i in range(half - 1)] + [SLATE["right"]])
    grid.append([SLATE["left"]] + [_pick(SLATE["slope_l"], i, 99, 1) for i in range(half - 2)] + SLATE["end"]
                + [_pick(SLATE["slope_r"], i, 99, 2) for i in range(half - 2)] + [SLATE["right"]])
    e = SLATE["eaves"]
    grid.append([e[0], e[1]] + [e[2]] * (half - 3) + [e[3], e[4], e[5]] + [e[6]] * (half - 3) + [e[7], e[8]])
    for k in range(front):
        grid.append([(PALE if pale else FACE)[min(k, 3)][i % 4] for i in range(w)])
    if windows and front >= 2:     # windows along the upper face, clear of the door and the corners
        for i in range(2, w - 2, 3):
            if abs(i - half) > 1:
                grid[len(grid) - front][i] = WINDOW
    if arcade:
        grid[-1] = [ARCADE[0]] + [ARCADE[1]] * (w - 2) + [ARCADE[2]]
    h = len(grid)
    above = [v for row in grid for v in row]
    solid = ["1" * w for _ in range(h)]
    below = [-1] * (w * h)
    st = {"w": w, "h": h, "door": [half, h - 1], "layers": {"above3": above}, "solid": solid}
    if door and not arcade:
        above[(h - 1) * w + half] = -1
        below[(h - 1) * w + half] = DOOR
        st["layers"]["below1"] = below
        solid[h - 1] = solid[h - 1][:half] + "0" + solid[h - 1][half + 1:]
    if arcade:                     # the arcade's middle stands open: a buttercross is a roof on arches, walked under
        solid[h - 1] = "1" + "0" * (w - 2) + "1"
    return st


def beside(a, b):
    """Stamp b set against stamp a's east side, their bottoms level (a church and its tower): a's door is the door."""
    w, h = a["w"] + b["w"], max(a["h"], b["h"])
    names = set(a["layers"]) | set(b["layers"])
    out = {"w": w, "h": h, "door": [a["door"][0], h - a["h"] + a["door"][1]], "layers": {n: [-1] * (w * h) for n in names},
           "solid": []}
    rows = [["0"] * w for _ in range(h)]
    for st, ox in ((a, 0), (b, a["w"])):
        oy = h - st["h"]
        for n, cells in st["layers"].items():
            for j in range(st["h"]):
                for i in range(st["w"]):
                    if cells[j * st["w"] + i] >= 0:
                        out["layers"][n][(oy + j) * w + ox + i] = cells[j * st["w"] + i]
        for j in range(st["h"]):
            for i in range(st["w"]):
                rows[oy + j][ox + i] = st["solid"][j][i]
    out["solid"] = ["".join(r) for r in rows]
    return out


def civic():
    paid = AssetZip(PAID)
    lay = _layers(paid, CASTLE)
    walls, objs = lay["Walls"], lay["Object"]
    kit = {"h": _cut(walls, WALL_H), "v": _cut(walls, WALL_V), "end": [r[0] for r in _cut(walls, WALL_END)],
           "banner": [objs[BANNER[1] * 30 + BANNER[0]], objs[(BANNER[1] + 1) * 30 + BANNER[0]]]}
    white = {}
    for r in range(4):
        for c in range(4):
            white[str(FACE[r][c])] = PALE[r][c]
    for k, v in enumerate(kit["end"][1:]):
        white[str(v)] = PALE[k][1]
    stamps = {
        "abbey": beside(slate_hall(13, 18, 3, windows=True), slate_hall(7, 5, 9, door=False)),
        "church": slate_hall(9, 9, 2, windows=True),
        "church_tower": beside(slate_hall(9, 9, 2, windows=True), slate_hall(7, 5, 6, door=False)),
        "keep": slate_hall(11, 7, 4, pale=True),
        "buttercross": slate_hall(7, 4, 1, arcade=True),
        "barrow": {"w": 3, "h": 3, "door": [1, 2], "layers": {"below0": [v for r in BARROW for v in r]}, "solid": ["000", "000", "000"]},
        "fountain": {"w": 2, "h": 2, "door": [0, 1], "layers": {"below0": [v for r in FOUNTAIN for v in r]}, "solid": ["11", "11"]},
    }
    return kit, white, stamps


def build():
    img = np.array(Image.open(TILES).convert("RGBA"))
    rows = img.shape[0] // 16
    village = json.loads(VILLAGE.read_text())

    def tile(t):
        x, y = (t % COLS) * 16, (t // COLS) * 16
        return img[y:y + 16, x:x + 16]

    out = {}
    for name, (off, stamps) in VARIANTS.items():
        swap = {}
        for sname in stamps:
            for cells in village["stamps"][sname]["layers"].values():
                for v in cells:
                    if not (0 <= v < 100000) or str(v) in swap:
                        continue
                    u = v + off
                    if u >= rows * COLS:
                        continue
                    a, b = tile(v)[:, :, 3] > 0, tile(u)[:, :, 3] > 0
                    if a.any() and (a == b).all() and not (tile(v)[:, :, :3] == tile(u)[:, :, :3]).all():
                        swap[str(v)] = u
        out[name] = {"stamps": stamps, "swap": dict(sorted(swap.items(), key=lambda kv: int(kv[0])))}
    kit, white, stamps = civic()
    out["white"] = {"stamps": ["wall"], "swap": white}
    return {"format": FORMAT, "variants": out, "wall": kit, "stamps": stamps}


def main():
    data = build()
    OUT.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    print(f"wrote {OUT.relative_to(REPO)}: " + ", ".join(f"{k} ({len(v['swap'])} tiles)" for k, v in data["variants"].items())
          + "; stamps " + ", ".join(f"{k} {v['w']}x{v['h']}" for k, v in data["stamps"].items()))


if __name__ == "__main__":
    main()
