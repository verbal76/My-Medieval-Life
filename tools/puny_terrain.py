"""Headless procedural terrain generator using the PUNY CHARACTERS terrain set.

Reads `orthogonal-tiles.tsx` from PUNY_CHARACTERS_v2.1.zip, which defines a
Tiled corner wangset ("Grass-Sand"). Its transitions form one elevation chain:

    DarkGrass(2) - LightGrass(1) - Sand(3) - LightWater(4) - DarkWater(5)

A fractal value-noise heightmap is sampled at tile corners, quantised onto that
chain, then repaired so every tile's four corners have a matching wang tile.
Writes a PNG and a Tiled-compatible .tmj map.

Usage:
    python3 tools/puny_terrain.py --size 64 40 --seed 3 -o out/terrain
"""
import argparse
import json
import random
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

from assetzip import AssetZip

ROOT = "PUNY_CHARACTERS_v2.1/PUNY CHARACTERS/Tiled-Maps/Orthogonal"
CHAIN = [5, 4, 3, 1, 2]  # wang colours from lowest to highest elevation
TILE = 16


def load_wangset(z):
    root = ET.fromstring(z.text(f"{ROOT}/orthogonal-tiles.tsx"))
    names = {}
    tiles = {}
    ws = root.find("wangsets/wangset")
    for i, wc in enumerate(ws.findall("wangcolor"), start=1):
        names[i] = wc.get("name")
    for wt in ws.findall("wangtile"):
        w = [int(v) for v in wt.get("wangid").split(",")]
        # corner order in wangid: TR=1, BR=3, BL=5, TL=7 -> store as (TL, TR, BR, BL)
        tiles.setdefault((w[7], w[1], w[3], w[5]), []).append(int(wt.get("tileid")))
    return names, tiles


def value_noise(w, h, rng, octaves=5, base=6):
    """Sum of bilinearly-interpolated random grids, normalised to 0..1."""
    total = [[0.0] * w for _ in range(h)]
    amp, cells, norm = 1.0, base, 0.0
    for _ in range(octaves):
        gw, gh = cells + 2, max(2, int(cells * h / max(w, 1))) + 2
        grid = [[rng.random() for _ in range(gw)] for _ in range(gh)]
        for y in range(h):
            fy = y / max(h - 1, 1) * (gh - 2)
            y0, ty = int(fy), fy - int(fy)
            ty = ty * ty * (3 - 2 * ty)
            for x in range(w):
                fx = x / max(w - 1, 1) * (gw - 2)
                x0, tx = int(fx), fx - int(fx)
                tx = tx * tx * (3 - 2 * tx)
                a = grid[y0][x0] + (grid[y0][x0 + 1] - grid[y0][x0]) * tx
                b = grid[y0 + 1][x0] + (grid[y0 + 1][x0 + 1] - grid[y0 + 1][x0]) * tx
                total[y][x] += (a + (b - a) * ty) * amp
        norm += amp
        amp *= 0.5
        cells *= 2
    lo = min(map(min, total))
    hi = max(map(max, total))
    return [[(v - lo) / (hi - lo) for v in row] for row in total]


def quantise(height, levels, sea=0.42):
    """Map 0..1 height onto chain indices, biased so ~`sea` of the map is water."""
    flat = sorted(v for row in height for v in row)
    cuts = [0.22, sea, sea + 0.08, 0.80]  # deep|shallow|sand|light grass|dark grass
    thresholds = [flat[int(c * (len(flat) - 1))] for c in cuts]
    return [[sum(v > t for t in thresholds) for v in row] for row in height]


def repair(level, tiles):
    """Raise corners until every 2x2 cell maps to an existing wang tile."""
    h, w = len(level), len(level[0])
    for _ in range(200):
        changed = False
        for y in range(h - 1):
            for x in range(w - 1):
                cs = [(y, x), (y, x + 1), (y + 1, x + 1), (y + 1, x)]
                key = tuple(CHAIN[level[cy][cx]] for cy, cx in cs)
                if key in tiles:
                    continue
                # too steep, or a diagonal pattern with no tile: raise the low
                # corners. Levels only go up, so this always terminates.
                lo = min(level[cy][cx] for cy, cx in cs)
                for cy, cx in cs:
                    if level[cy][cx] == lo:
                        level[cy][cx] += 1
                changed = True
        if not changed:
            return level
    raise RuntimeError("terrain did not converge")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--size", type=int, nargs=2, default=[48, 32], metavar=("W", "H"))
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--sea", type=float, default=0.42, help="fraction of map that is water")
    ap.add_argument("-n", type=int, default=1, help="how many maps")
    ap.add_argument("-o", "--out", default="out/terrain")
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()

    z = AssetZip("PUNY_CHARACTERS_v2.1.zip")
    names, tiles = load_wangset(z)
    sheet = z.image(f"{ROOT}/Orthogonal-tiles.png")
    cols = sheet.width // TILE
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rng = random.Random(args.seed)
    w, h = args.size

    for n in range(args.n):
        level = repair(quantise(value_noise(w + 1, h + 1, rng), len(CHAIN), args.sea), tiles)
        img = Image.new("RGBA", (w * TILE, h * TILE))
        data = []
        for y in range(h):
            for x in range(w):
                key = (CHAIN[level[y][x]], CHAIN[level[y][x + 1]],
                       CHAIN[level[y + 1][x + 1]], CHAIN[level[y + 1][x]])
                tid = rng.choice(tiles[key])
                data.append(tid + 1)
                sx, sy = (tid % cols) * TILE, (tid // cols) * TILE
                img.alpha_composite(sheet.crop((sx, sy, sx + TILE, sy + TILE)), (x * TILE, y * TILE))
        name = f"terrain_{n:02d}"
        img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST) \
            .save(out / f"{name}.png")
        tmj = {
            "type": "map", "orientation": "orthogonal", "renderorder": "right-down",
            "width": w, "height": h, "tilewidth": TILE, "tileheight": TILE,
            "infinite": False, "nextlayerid": 2, "nextobjectid": 1,
            "layers": [{"id": 1, "name": "Ground", "type": "tilelayer", "x": 0, "y": 0,
                        "width": w, "height": h, "opacity": 1, "visible": True, "data": data}],
            "tilesets": [{"firstgid": 1, "source": "orthogonal-tiles.tsx"}],
        }
        (out / f"{name}.tmj").write_text(json.dumps(tmj))
        counts = {}
        for row in level:
            for v in row:
                counts[names[CHAIN[v]]] = counts.get(names[CHAIN[v]], 0) + 1
        print(name, counts)


if __name__ == "__main__":
    main()
