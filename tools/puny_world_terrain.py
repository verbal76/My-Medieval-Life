"""Headless overworld generator using the free PUNY WORLD tileset's Tiled terrains.

PUNY_WORLD_v1.zip ships `punyworld-overworld-tiles.tsx` with a corner wangset
("overworld"). Its transitions are:

    ground:  seawater-deep - seawater-medium - seawater-light - sand - grass
             grass - dirt, grass - river, grass - cliff
    overlay: air - trees, air - trees2 (drawn on a second layer over the ground)

A noise heightmap picks the ground level at each tile corner; dirt patches are
sprinkled on grass, and a separate forest noise places trees on the overlay
layer (only over grass). Corners are repaired until every cell has a real
wang tile, so the result is also a valid Tiled map (.tmj, two layers).

Usage:
    python3 tools/puny_world_terrain.py --size 64 40 --seed 3 -n 2
"""
import argparse
import json
import posixpath
import random
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

from assetzip import AssetZip
from puny_terrain import value_noise

ZIP = "PUNY_WORLD_v1.zip"
TSX = "PUNY_WORLD_v1/PUNY_WORLD_v1/Tiled/punyworld-overworld-tiles.tsx"
T = 16
CHAIN = ["seawater-deep", "seawater-medium", "seawater-light", "sand", "grass"]
SHARES = [0.0, 0.16, 0.27, 0.36, 0.42]  # share of map at or below each level


def load(z):
    root = ET.fromstring(z.text(TSX))
    cols = int(root.get("columns"))
    img = z.image(posixpath.normpath(posixpath.join(posixpath.dirname(TSX),
                                                    root.find("image").get("source"))))
    ws = next(w for w in root.iter("wangset") if w.get("name") == "overworld")
    ids = {c.get("name"): i for i, c in enumerate(ws.findall("wangcolor"), start=1)}
    tiles = {}
    for wt in ws.findall("wangtile"):
        w = [int(v) for v in wt.get("wangid").split(",")]
        tiles.setdefault((w[7], w[1], w[3], w[5]), []).append(int(wt.get("tileid")))
    return img, cols, ids, tiles


def cell_keys(grid, x, y):
    return (grid[y][x], grid[y][x + 1], grid[y + 1][x + 1], grid[y + 1][x])


def repair_chain(level, ok):
    """Raise the lowest corners of any cell without a tile (steps >1 or a missing
    diagonal). Levels only go up, so this always terminates."""
    h, w = len(level), len(level[0])
    for _ in range(300):
        changed = False
        for y in range(h - 1):
            for x in range(w - 1):
                if ok(cell_keys(level, x, y)):
                    continue
                cs = [(y, x), (y, x + 1), (y + 1, x + 1), (y + 1, x)]
                lo = min(level[cy][cx] for cy, cx in cs)
                for cy, cx in cs:
                    if level[cy][cx] == lo:
                        level[cy][cx] += 1
                changed = True
        if not changed:
            return
    raise RuntimeError("ground did not converge")


def drop_invalid(grid, ok, value, fallback):
    """Turn `value` corners back into `fallback` wherever a cell has no tile."""
    h, w = len(grid), len(grid[0])
    for _ in range(300):
        changed = False
        for y in range(h - 1):
            for x in range(w - 1):
                if not ok(cell_keys(grid, x, y)):
                    for cy, cx in [(y, x), (y, x + 1), (y + 1, x + 1), (y + 1, x)]:
                        if grid[cy][cx] == value:
                            grid[cy][cx] = fallback
                            changed = True
        if not changed:
            return


def generate(w, h, rng, ids, tiles):
    ok = lambda key: key in tiles
    height = value_noise(w + 1, h + 1, rng)
    flat = sorted(v for row in height for v in row)
    cut = [flat[int(s * (len(flat) - 1))] for s in SHARES]
    level = [[max(i for i, c in enumerate(cut) if v >= c) for v in row] for row in height]
    chain_ids = [ids[n] for n in CHAIN]
    repair_chain(level, lambda key: ok(tuple(chain_ids[k] for k in key)))
    ground = [[chain_ids[v] for v in row] for row in level]

    # dirt patches on high grass
    dirt = value_noise(w + 1, h + 1, rng, octaves=3, base=5)
    for y in range(h + 1):
        for x in range(w + 1):
            if ground[y][x] == ids["grass"] and dirt[y][x] > 0.8:
                ground[y][x] = ids["dirt"]
    drop_invalid(ground, ok, ids["dirt"], ids["grass"])

    # forest overlay over grass only
    forest = value_noise(w + 1, h + 1, rng, octaves=4, base=4)
    over = [[ids["trees"] if ground[y][x] == ids["grass"] and forest[y][x] > 0.55 and height[y][x] > cut[-1] + 0.08
             else ids["air"] for x in range(w + 1)] for y in range(h + 1)]
    drop_invalid(over, ok, ids["trees"], ids["air"])
    return ground, over


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--size", type=int, nargs=2, default=[48, 32], metavar=("W", "H"))
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("-n", type=int, default=1)
    ap.add_argument("-o", "--out", default="out/punyworld")
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()

    z = AssetZip(ZIP)
    sheet, cols, ids, tiles = load(z)
    air_full = (ids["air"],) * 4
    rng = random.Random(args.seed)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    w, h = args.size

    for n in range(args.n):
        ground, over = generate(w, h, rng, ids, tiles)
        img = Image.new("RGBA", (w * T, h * T))
        layers = []
        for grid in (ground, over):
            data = []
            for y in range(h):
                for x in range(w):
                    key = cell_keys(grid, x, y)
                    if key == air_full:
                        data.append(0)
                        continue
                    tid = rng.choice(tiles[key])
                    data.append(tid + 1)
                    sx, sy = (tid % cols) * T, (tid // cols) * T
                    img.alpha_composite(sheet.crop((sx, sy, sx + T, sy + T)), (x * T, y * T))
            layers.append(data)
        name = f"punyworld_{n:02d}"
        img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST) \
            .save(out / f"{name}.png")
        tmj = {
            "type": "map", "orientation": "orthogonal", "renderorder": "right-down",
            "width": w, "height": h, "tilewidth": T, "tileheight": T, "infinite": False,
            "nextlayerid": 3, "nextobjectid": 1,
            "layers": [{"id": i + 1, "name": nm, "type": "tilelayer", "x": 0, "y": 0,
                        "width": w, "height": h, "opacity": 1, "visible": True, "data": d}
                       for i, (nm, d) in enumerate(zip(("Ground", "Trees"), layers))],
            "tilesets": [{"firstgid": 1, "source": "punyworld-overworld-tiles.tsx"}],
        }
        (out / f"{name}.tmj").write_text(json.dumps(tmj))
        print("wrote", out / f"{name}.png")


if __name__ == "__main__":
    main()
