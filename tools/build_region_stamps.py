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

from assetzip import REPO

OUT = REPO / "game" / "data" / "region_stamps.json"
VILLAGE = REPO / "game" / "data" / "village.json"
TILES = REPO / "game" / "assets" / "tiles" / "punyworld-tiles.png"
COLS = 220
FORMAT = "mml-region-stamps/1"
# variant name -> (tile offset in the paid atlas, stamps it applies to). "thatch": the straw roof, 16 rows below the tiled one.
VARIANTS = {"thatch": (16 * COLS, ["house"])}


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
    return {"format": FORMAT, "variants": out}


def main():
    data = build()
    OUT.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    print(f"wrote {OUT.relative_to(REPO)}: " + ", ".join(f"{k} ({len(v['swap'])} tiles)" for k, v in data["variants"].items()))


if __name__ == "__main__":
    main()
