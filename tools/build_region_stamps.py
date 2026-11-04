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
VARIANTS = {"thatch": (16 * COLS, ["house", "house_*"])}


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


def beside(a, b, door="a"):
    """Stamp b set against stamp a's east side, their bottoms level (a church and its tower): a's door is the door (b's with
    door="b")."""
    w, h = a["w"] + b["w"], max(a["h"], b["h"])
    names = set(a["layers"]) | set(b["layers"])
    dd = [a["door"][0], h - a["h"] + a["door"][1]] if door == "a" else [a["w"] + b["door"][0], h - b["h"] + b["door"][1]]
    out = {"w": w, "h": h, "door": dd, "layers": {n: [-1] * (w * h) for n in names}, "solid": []}
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


# --- the region's houses and yards (B25R1-018, owner B25R1-Q8: "owned art", towns that are not rows of identical houses) -------
# Shade's small house (village.json "house", 9 x 10: roof rows 1-6 with the ridge in column 4, eaves row 7, front row 8, step
# row 9) resampled: a wider house repeats the slope columns 2 and 6, a narrower one drops them; a deeper one repeats the roof's
# middle rows. The ivy (layer above4) is left off, so the roofs read clean; the original keeps it. Windows sit two columns
# either side of the door (and four, on the widest).
HOUSE_SHAPES = {"house_7": (7, 10), "house_11": (11, 10), "house_13": (13, 11), "house_9d": (9, 12), "house_11d": (11, 12),
                "house_7d": (7, 11)}
WIN, WALL = 3659, 945
# Buildings cut whole from the village map (village.json layers and solid grid, its wang grass left out): x, y, w, h, door.
# A site building is not entered: every roofed cell is solid but the door.
CUTS = {"manor": (14, 36, 15, 18, (9, 16)), "inn": (34, 38, 23, 14, (4, 13)), "hall": (67, 40, 17, 14, (4, 13)),
        "shed": (39, 31, 3, 3, (1, 2))}
WELL = [[3007, 3008], [3227, 3228], [3447, 3448]]
PAID_COLS = 220
GROWING, RIPE = 7 * PAID_COLS + 207, 11 * PAID_COLS + 207
COZY = 200000
FENCE = {"tl": COZY + 29 * 54 + 4, "t": COZY + 29 * 54 + 5, "tr": COZY + 29 * 54 + 6, "l": COZY + 30 * 54 + 4,
         "r": COZY + 30 * 54 + 6, "bl": COZY + 31 * 54 + 4, "b": COZY + 31 * 54 + 5, "br": COZY + 31 * 54 + 6}
TOMB = 800000                      # MapView atlas 8 (EXTRA_ATLASES; tools/region_props.py): eight tombstones, 800000-800007


def resample(src, w, h, ivy=False):
    sw, sh = src["w"], src["h"]
    n = (w - 3) // 2
    side = [1] + [2] * max(0, n - 2) + ([3] if n >= 2 else [])
    cols = [0] + side + [4] + [c + 4 for c in side] + [8]
    m = h - 4
    mid = [2, 3, 4, 5]
    roof = [1] + [mid[k % 4] for k in range(m - 2)] + [6] if m >= 2 else [1]
    if m == 5:
        roof = [1, 2, 4, 5, 6]
    rows = [0] + roof + [7, 8, 9]
    half = (w - 1) // 2
    out = {"w": w, "h": h, "door": [half, h - 2], "layers": {}}
    for name, cells in src["layers"].items():
        if name == "above4" and not ivy:
            continue
        out["layers"][name] = [cells[r * sw + c] for r in rows for c in cols]
    front = out["layers"]["above3"]
    wins = {half - 2, half + 2} | ({half - 4, half + 4} if w >= 13 else set())
    for i in range(w):
        k = (h - 2) * w + i
        if front[k] == WIN and i not in wins:
            front[k] = WALL
        elif i in wins and 0 < i < w - 1:
            front[k] = WIN
    out["solid"] = ["".join(src["solid"][r][c] for c in cols) for r in rows]
    return out


def cut(village, x0, y0, w, h, door):
    W = village["w"]
    out = {"w": w, "h": h, "door": list(door), "layers": {}}
    roofed = set()
    for lay in village["layers"]:
        if lay["name"] == "ground0":
            continue
        cells = [lay["data"][(y0 + y) * W + x0 + x] for y in range(h) for x in range(w)]
        if any(v >= 0 for v in cells):
            out["layers"][lay["name"]] = cells
            if lay["name"] in ("above3", "above4", "above5"):
                roofed |= {i for i, v in enumerate(cells) if v >= 0}
    solid = village["solid"]
    out["solid"] = ["".join("0" if (x, y) == tuple(door) else "1" if (y * w + x) in roofed or solid[y0 + y][x0 + x] == "1" else "0"
                            for x in range(w)) for y in range(h)]
    return out


def flat(rows, solid_rows, door, layer="below0"):
    h, w = len(rows), len(rows[0])
    return {"w": w, "h": h, "door": list(door), "layers": {layer: [v for r in rows for v in r]}, "solid": solid_rows}


def field(base, w, h):
    def t(i, j):
        col = 0 if w == 1 else 1 if i == 0 else 3 if i == w - 1 else 2
        row = 3 if h == 1 else 0 if j == 0 else 2 if j == h - 1 else 1
        return base + row * PAID_COLS + col
    return [[t(i, j) for i in range(w)] for j in range(h)]


def fenced(inner, w, h, gate=True):
    """A fence ring w x h round `inner` (rows, or None), open for two cells in the middle of its south side."""
    g = [[-1] * w for _ in range(h)]
    sol = [["0"] * w for _ in range(h)]
    for x in range(w):
        for y in (0, h - 1):
            g[y][x] = FENCE[("t" if y == 0 else "b")]
            sol[y][x] = "1"
    for y in range(h):
        for x in (0, w - 1):
            g[y][x] = FENCE[("l" if x == 0 else "r")]
            sol[y][x] = "1"
    g[0][0], g[0][w - 1], g[h - 1][0], g[h - 1][w - 1] = FENCE["tl"], FENCE["tr"], FENCE["bl"], FENCE["br"]
    if gate:
        for x in (w // 2 - 1, w // 2):
            g[h - 1][x] = -1
            sol[h - 1][x] = "0"
    layers = {"below2": [v for r in g for v in r]}
    if inner:
        layers["path1"] = [-1] * (w * h)
        for j, row in enumerate(inner):
            for i, v in enumerate(row):
                layers["path1"][(j + 1) * w + i + 1] = v
    return {"w": w, "h": h, "door": [w // 2, h - 1], "layers": layers, "solid": ["".join(r) for r in sol]}


def churchyard(w, h, salt):
    """A fenced churchyard w x h, its gate in the middle of the south side; tombstones in loose rows, two cells apart."""
    st = fenced(None, w, h)
    tombs = [-1] * (w * h)
    sol = [list(r) for r in st["solid"]]
    for y in range(2, h - 2, 2):
        for x in range(2, w - 2, 2):
            if (x * 7 + y * 13 + salt) % 5 == 0 or abs(x - w // 2) <= 1:
                continue
            tombs[y * w + x] = TOMB + (x * 3 + y * 5 + salt) % 8
            sol[y][x] = "1"
    st["layers"]["below1"] = tombs
    st["solid"] = ["".join(r) for r in sol]
    return st


def houses(village):
    src = village["stamps"]["house"]
    out = {name: resample(src, w, h) for name, (w, h) in HOUSE_SHAPES.items()}
    out["house_9"] = resample(src, 9, 10)
    for name, (x, y, w, h, door) in CUTS.items():
        out[name] = cut(village, x, y, w, h, door)
    out["well"] = flat(WELL, ["11", "11", "11"], (0, 2), "below1")
    out["garden"] = fenced(field(GROWING, 4, 3), 6, 5)
    out["garden_w"] = fenced(field(RIPE, 6, 3), 8, 5)
    out["plot"] = flat(field(GROWING, 4, 2), ["0000", "0000"], (0, 1), "path1")
    out["woodpile"] = flat([[1025, 1024]], ["11"], (0, 0), "below1")
    out["barrels"] = flat([[358, 3502, 796]], ["111"], (0, 0), "below1")
    # Larchrow's village pieces (owner's pack, B25R1-Q8; MapView atlas 5, docs/assets/LARCHROW_TILES.md): only the small props,
    # whose bold outline sits well enough beside Shade's art; his roofs and walls are drawn straight down, not in Shade's
    # three-quarter view, and are not used
    L = 500000
    out["stall"] = {"w": 2, "h": 2, "door": [0, 1], "layers": {"above1": [L + 137, L + 138, -1, -1], "below1": [-1, -1, L + 139, L + 140],
                    "path0": [-1, -1, 400015, 400015]}, "solid": ["00", "11"]}   # (the market's paving under the counter: road atlas 4)
    out["signpost"] = flat([[L + 141]], ["1"], (0, 0), "below1")
    out["lamp"] = {"w": 1, "h": 2, "door": [0, 1], "layers": {"above1": [L + 144, -1], "below1": [-1, L + 145]}, "solid": ["0", "1"]}
    out["haystack"] = flat([[L + 16]], ["1"], (0, 0), "below1")
    out["apples"] = flat([[L + 148, L + 146]], ["11"], (0, 0), "below1")
    out["casks"] = flat([[L + 146, L + 147]], ["11"], (0, 0), "below1")
    out["churchyard"] = churchyard(13, 9, 1)
    out["churchyard_s"] = churchyard(9, 7, 2)
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
        # B25R1-018 (lead review: "the churches read as dark blocks"): pale stone fronts, a lower roof, and the tower a
        # narrow pale shaft standing well above the nave under a short slate cap
        # (the tower at the west end: the stamp's top-left cell is solid, as every building's is)
        "abbey": beside(beside(slate_hall(7, 3, 13, door=False, pale=True, windows=True), slate_hall(15, 7, 4, pale=True, windows=True), "b"),
                        slate_hall(11, 4, 3, door=False, pale=True, windows=True)),
        "church": slate_hall(9, 5, 3, pale=True, windows=True),
        "church_tower": beside(slate_hall(7, 3, 9, door=False, pale=True, windows=True), slate_hall(9, 5, 3, pale=True, windows=True), "b"),
        "keep": slate_hall(11, 7, 4, pale=True),
        "buttercross": slate_hall(7, 4, 1, arcade=True),
        "barrow": {"w": 3, "h": 3, "door": [1, 2], "layers": {"below0": [v for r in BARROW for v in r]}, "solid": ["000", "000", "000"]},
        "fountain": {"w": 2, "h": 2, "door": [0, 1], "layers": {"below0": [v for r in FOUNTAIN for v in r], "path0": [400015] * 4},
                     "solid": ["11", "11"]},   # (stands on the market's paving: road atlas 4, stone, all sides joined)
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
        for sname in [n for n in stamps if n in village["stamps"]]:
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
    stamps.update(houses(village))
    return {"format": FORMAT, "variants": out, "wall": kit, "stamps": stamps}


def main():
    data = build()
    OUT.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    print(f"wrote {OUT.relative_to(REPO)}: " + ", ".join(f"{k} ({len(v['swap'])} tiles)" for k, v in data["variants"].items())
          + "; stamps " + ", ".join(f"{k} {v['w']}x{v['h']}" for k, v in data["stamps"].items()))


if __name__ == "__main__":
    main()
