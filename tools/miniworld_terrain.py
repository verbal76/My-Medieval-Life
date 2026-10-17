"""Headless layered terrain generator using the miniworld+ terrain modules.

miniworld+ (octoshrimpy, CC BY 4.0 - credit required) draws every terrain in
terrain.png as a "module" with one shared layout:

    blob  (48x48 at bx,by)      3x3 tiles: outer corners, edges, full centre
    holes (32x32 at bx+48,by)   2x2 tiles around a hole: the 4 inner corners
    extra opaque tiles beside the hole block are alternative full tiles

Tiles are transparent outside the terrain, so maps are built in layers: the
lowest terrain fills the map, then each higher terrain is auto-tiled on top
from a corner mask (height >= threshold). The two diagonal corner cases have
no tile and are drawn as two single-corner tiles composited together.

Usage:
    python3 tools/miniworld_terrain.py --biome temperate --size 64 40 --seed 3
    python3 tools/miniworld_terrain.py --biome winter -n 3 -o out/miniworld
"""
import argparse
import json
import random
from pathlib import Path

from PIL import Image

from assetzip import AssetZip
from puny_terrain import value_noise

ZIP = "miniworld +__rainbow-refresh.zip"
T = 16

# module name -> blob origin in terrain.png
MODULES = {
    "pale": (0, 0), "shallow": (0, 48), "water": (0, 96), "deep": (0, 144),
    "pale-rim": (96, 0), "shallow-rim": (96, 48), "water-rim": (96, 96), "deep-rim": (96, 144),
    "sand": (176, 0), "light-grass": (176, 48), "grass": (176, 96),
    "forest": (288, 0), "dark-forest": (288, 48), "snow": (288, 96),
    "ice": (384, 0), "dirt": (384, 48), "dark-dirt": (384, 96),
}

# biome -> layers from lowest to highest, with the share of the map at or below each
BIOMES = {
    "temperate": [("deep", 0.0), ("water", 0.18), ("shallow", 0.30), ("sand", 0.40),
                  ("light-grass", 0.47), ("grass", 0.62), ("forest", 0.80), ("dark-forest", 0.92)],
    "winter": [("deep", 0.0), ("water", 0.20), ("ice", 0.33), ("snow", 0.45),
               ("forest", 0.78), ("dark-forest", 0.90)],
    "desert": [("deep", 0.0), ("water", 0.10), ("shallow", 0.17), ("sand", 0.24),
               ("dirt", 0.70), ("dark-dirt", 0.88)],
    "marsh": [("water", 0.0), ("shallow", 0.25), ("light-grass", 0.42), ("dirt", 0.55),
              ("grass", 0.65), ("dark-forest", 0.85)],
}

# corners as bits: TL=8, TR=4, BR=2, BL=1
TL, TR, BR, BL = 8, 4, 2, 1
BLOB = {  # blob tile (col,row) -> corners it covers
    (0, 0): BR, (1, 0): BL | BR, (2, 0): BL,
    (0, 1): TR | BR, (1, 1): TL | TR | BR | BL, (2, 1): TL | BL,
    (0, 2): TR, (1, 2): TL | TR, (2, 2): TL,
}
HOLES = {(0, 0): 15 & ~BR, (1, 0): 15 & ~BL, (0, 1): 15 & ~TR, (1, 1): 15 & ~TL}


class Module:
    def __init__(self, sheet, bx, by):
        crop = lambda x, y: sheet.crop((x, y, x + T, y + T))
        self.tiles = {}
        for (c, r), mask in BLOB.items():
            self.tiles[mask] = [crop(bx + c * T, by + r * T)]
        for (c, r), mask in HOLES.items():
            self.tiles[mask] = [crop(bx + 48 + c * T, by + r * T)]
        # alternative full tiles: opaque tiles next to the hole block
        for x in range(bx + 48, bx + 96, T):
            for y in range(by, by + 48, T):
                if x < bx + 80 and y < by + 32:
                    continue
                tile = crop(x, y)
                if tile.width == T and tile.getextrema()[3][0] == 255:
                    self.tiles[15].append(tile)
        self.tiles[TL | BR] = [self._merge(TL, BR)]
        self.tiles[TR | BL] = [self._merge(TR, BL)]

    def _merge(self, a, b):
        im = self.tiles[a][0].copy()
        im.alpha_composite(self.tiles[b][0])
        return im

    def tile(self, mask, rng):
        opts = self.tiles[mask]
        # keep plain fill most of the time so decorations stay sparse
        return opts[0] if len(opts) == 1 or rng.random() < 0.85 else rng.choice(opts[1:])


def generate(w, h, biome, rng, sheet):
    layers = BIOMES[biome]
    height = value_noise(w + 1, h + 1, rng)
    flat = sorted(v for row in height for v in row)
    cut = [flat[int(share * (len(flat) - 1))] for _, share in layers]
    level = [[max(i for i, c in enumerate(cut) if v >= c) for v in row] for row in height]

    img = Image.new("RGBA", (w * T, h * T))
    for i, (name, _) in enumerate(layers):
        mod = Module(sheet, *MODULES[name])
        for y in range(h):
            for x in range(w):
                corners = [level[y][x], level[y][x + 1], level[y + 1][x + 1], level[y + 1][x]]
                mask = sum(bit for bit, lv in zip((TL, TR, BR, BL), corners) if lv >= i)
                if i == 0:
                    mask = 15
                if mask:
                    img.alpha_composite(mod.tile(mask, rng), (x * T, y * T))
    return img, level


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--biome", choices=sorted(BIOMES), default="temperate")
    ap.add_argument("--size", type=int, nargs=2, default=[48, 32], metavar=("W", "H"))
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("-n", type=int, default=1, help="how many maps")
    ap.add_argument("-o", "--out", default="out/miniworld")
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()

    sheet = AssetZip(ZIP).image("terrain.png")
    rng = random.Random(args.seed)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    w, h = args.size
    for n in range(args.n):
        img, level = generate(w, h, args.biome, rng, sheet)
        name = f"{args.biome}_{n:02d}"
        img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST) \
            .save(out / f"{name}.png")
        # corner grid of layer indices, so a game can rebuild or query the map
        (out / f"{name}.json").write_text(json.dumps({
            "biome": args.biome, "tile": T, "width": w, "height": h,
            "layers": [name for name, _ in BIOMES[args.biome]],
            "corner_levels": level,
        }))
        print("wrote", out / f"{name}.png")


if __name__ == "__main__":
    main()
