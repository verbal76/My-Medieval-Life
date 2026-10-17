"""Headless overworld generator using the free PUNY WORLD tileset's Tiled terrains.

PUNY_WORLD_v1.zip ships `punyworld-overworld-tiles.tsx` with a corner wangset
("overworld"). Its transitions are:

    ground:  seawater-deep - seawater-medium - seawater-light - sand - grass
             grass - dirt, grass - river, grass - cliff
    overlay: air - trees, air - trees2 (drawn on a second layer over the ground)

A noise heightmap picks the ground level at each tile corner; dirt patches are
sprinkled on grass, and a separate forest noise places trees on the overlay
layer (only over grass). Corners are repaired until every cell has a real
wang tile.

puny_world_features.py then adds rivers (streams, wide reaches, tributaries),
settlement sites, roads linking them, and bridges. Output per map:

    punyworld_s<seed>.png            preview
    punyworld_s<seed>.tmj            Tiled map: Ground, Trees, Bridges layers
    punyworld_s<seed>.features.json  sites, river and road courses, bridges

The same seed and arguments always give the same map.

Usage:
    python3 tools/puny_world_terrain.py --size 64 40 --seed 3 -n 4
    python3 tools/puny_world_terrain.py --rivers 0 --sites 0   # terrain only
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
from puny_world_features import DIRS, ROCK_RIVER, Features

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
    # edge wangset: path colour -> {(N, E, S, W) connected flags: [tile ids]}
    pw = next(w for w in root.iter("wangset") if w.get("name") == "pathways")
    pids = {c.get("name"): i for i, c in enumerate(pw.findall("wangcolor"), start=1)}
    paths = {"dirt": {}, "water": {}}
    for wt in pw.findall("wangtile"):
        w = [int(v) for v in wt.get("wangid").split(",")]
        edges = (w[0], w[2], w[4], w[6])
        for name, colour in (("dirt", pids["dirt-paths"]), ("water", pids["water-paths"])):
            if set(edges) <= {0, colour}:
                paths[name].setdefault(tuple(e == colour for e in edges), []).append(int(wt.get("tileid")))
    return img, cols, ids, tiles, paths


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
    return ground, over, height


def path_tile(paths, kind, dirs, rng):
    return rng.choice(paths[kind][tuple(d in dirs for d in DIRS)])


def build_map(w, h, seed, rivers=1, tributaries=1, sites=4, exits=1, assets=None):
    """Generate one map. Returns (layers, features) where layers maps layer name
    to a row-major list of tile ids (-1 = empty)."""
    sheet, cols, ids, tiles, paths = assets or load(AssetZip(ZIP))
    rng = random.Random(seed)
    ground, over, height = generate(w, h, rng, ids, tiles)
    feat = Features(w, h, ground, height, ids, rng)
    if rivers:
        feat.make_rivers(rivers, tributaries)
    if sites:
        feat.make_sites(sites, exits)
        feat.make_roads()
    feat.clear_ground_and_trees(over)

    river, grass = ids["river"], ids["grass"]
    layers = {"Ground": [], "Trees": [], "Bridges": []}
    for y in range(h):
        for x in range(w):
            c = (x, y)
            if c in feat.connectors:
                tid = feat.connectors[c]
            elif feat.touches_body(c):
                key = tuple(river if k in feat.body else grass
                            for k in [(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
                tid = rng.choice(tiles[key])
                if key == (river,) * 4 and rng.random() < 0.06:
                    tid = ROCK_RIVER
            elif c in feat.stream:
                tid = path_tile(paths, "water", feat.stream[c], rng)
            elif c in feat.road:
                tid = path_tile(paths, "dirt", feat.road[c], rng)
            else:
                tid = rng.choice(tiles[cell_keys(ground, x, y)])
            layers["Ground"].append(tid)
            key = cell_keys(over, x, y)
            layers["Trees"].append(-1 if key == (ids["air"],) * 4 else rng.choice(tiles[key]))
            layers["Bridges"].append(feat.bridges.get(c, -1))
    return layers, feat


def render(layers, w, h, sheet, cols):
    img = Image.new("RGBA", (w * T, h * T))
    for data in layers.values():
        for i, tid in enumerate(data):
            if tid >= 0:
                sx, sy = (tid % cols) * T, (tid // cols) * T
                img.alpha_composite(sheet.crop((sx, sy, sx + T, sy + T)), ((i % w) * T, (i // w) * T))
    return img


def to_tmj(layers, w, h):
    return {
        "type": "map", "orientation": "orthogonal", "renderorder": "right-down",
        "width": w, "height": h, "tilewidth": T, "tileheight": T, "infinite": False,
        "nextlayerid": len(layers) + 1, "nextobjectid": 1,
        "layers": [{"id": i + 1, "name": name, "type": "tilelayer", "x": 0, "y": 0,
                    "width": w, "height": h, "opacity": 1, "visible": True,
                    "data": [t + 1 for t in data]}
                   for i, (name, data) in enumerate(layers.items())],
        "tilesets": [{"firstgid": 1, "source": "punyworld-overworld-tiles.tsx"}],
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--size", type=int, nargs=2, default=[48, 32], metavar=("W", "H"))
    ap.add_argument("--seed", type=int, default=0, help="first seed; map k uses seed+k")
    ap.add_argument("-n", type=int, default=1)
    ap.add_argument("--rivers", type=int, default=1)
    ap.add_argument("--tributaries", type=int, default=1)
    ap.add_argument("--sites", type=int, default=4, help="settlements to link by road (0 = no roads)")
    ap.add_argument("--exits", type=int, default=1, help="roads leaving the map edge")
    ap.add_argument("-o", "--out", default="out/punyworld")
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()

    assets = load(AssetZip(ZIP))
    sheet, cols = assets[0], assets[1]
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    w, h = args.size
    for k in range(args.n):
        seed = args.seed + k
        layers, feat = build_map(w, h, seed, args.rivers, args.tributaries, args.sites,
                                 args.exits, assets)
        name = f"punyworld_s{seed}"
        img = render(layers, w, h, sheet, cols)
        img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST) \
            .save(out / f"{name}.png")
        (out / f"{name}.tmj").write_text(json.dumps(to_tmj(layers, w, h)))
        (out / f"{name}.features.json").write_text(json.dumps({"seed": seed, **feat.summary()}))
        print("wrote", out / f"{name}.png", f"rivers={len(feat.rivers)} roads={len(feat.roads)} "
              f"bridges={len(feat.bridges)} sites={len(feat.sites)}")


if __name__ == "__main__":
    main()
