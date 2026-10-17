"""Headless random character generator for PUNY CHARACTERS (TDSM edition).

This is a Python port of the logic in the pack's `manifest.tds` (a style
script for Top-Down Sprite Maker): the same layers, draw order, CSV choice
lists, "no choice" probabilities and palette-ramp recolouring. It reads the
assets straight from PUNY_CHARACTERS_v2.1_tdsm-2026.zip.

Usage:
    python3 tools/puny_chargen.py -n 12 --seed 7 -o out/characters
    python3 tools/puny_chargen.py -n 4 --none-prob facial-hair=0.6 jaw=0.8
"""
import argparse
import json
import random
from pathlib import Path

from PIL import Image

from assetzip import AssetZip

DIM = 32
DIRECTIONS = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]  # sheet rows
FRAMES = 29  # sheet columns

# anim id -> (sheet columns, durations in TDSM ticks)
ANIMS = {
    "idle": ([0, 1], [15, 15]),
    "walk": ([2, 3, 4], [7, 10, 7]),
    "sword": ([5, 6, 7, 8], [15, 10, 10, 10]),
    "bow": ([9, 10, 11, 12], [15, 10, 10, 10]),
    "stave": ([13, 14, 15], [15, 10, 10]),
    "throw": ([16, 17, 18], [15, 10, 25]),
    "hurt": ([1, 19, 20, 21], [15, 15, 15, 15]),
    "death": ([1, 22, 23, 24, 23], [20, 10, 5, 5, 50]),
    "carry": ([26, 25, 27], [7, 10, 7]),
    "jump": ([1, 0, 25, 28], [5, 5, 5, 30]),
}
TICK_MS = 1000 / 60  # assumption: TDSM ticks at 60 per second

# csv ramp tag -> list of (ramp, colour-selection) pairs, as in ramp_post_split
RAMP_TAGS = {
    "skin": [("skin", "skin")],
    "skeleton": [("skeleton", "skeleton")],
    "mage": [("mage", "mage")],
    "bandana": [("bandana", "bandana")],
    "headwear": [("clothes", "headwear")],
    "japan-4-step": [("japan-4-step", "j4s")],
    "japan-6-step": [("japan-6-step", "j6s")],
    "musketeer-hat": [("musketeer", "musketeer_hat")],
    "h-metal": [("metal", "metal_headwear")],
    "h-metal-accent": [("metal", "metal_headwear"), ("clothes", "headwear_accent")],
    "h-mongol": [("metal", "metal_headwear"), ("mongol-3-step", "m3s")],
    "s-metal": [("metal", "metal_shoes")],
    "s-leather": [("leather", "leather_shoes")],
    "clothes": [("clothes", "clothes")],
    "c-metal": [("metal", "metal_armour")],
    "c-musketeer": [("musketeer", "c_musketeer")],
    "c-bandana": [("bandana", "c_bandana")],
    "c-j4s": [("japan-4-step", "c_j4s")],
    "c-j6s": [("japan-6-step", "c_j6s")],
    "tunic": [("tunic", "tunic")],
    "g-metal": [("metal", "metal_gloves")],
    "g-leather": [("leather", "leather_gloves")],
}

# colour selection -> ramp it picks a row (swatch) from
SELECTIONS = {
    "skin": "skin", "skeleton": "skeleton", "hair": "hair",
    "facial_hair": "hair", "eyes": "eyes", "mage": "mage",
    "bandana": "bandana", "m3s": "mongol-3-step", "j4s": "japan-4-step",
    "j6s": "japan-6-step", "musketeer_hat": "musketeer", "headwear": "clothes",
    "headwear_accent": "clothes", "metal_headwear": "metal", "clothes": "clothes",
    "metal_armour": "metal", "c_musketeer": "musketeer", "c_bandana": "bandana",
    "c_j4s": "japan-4-step", "c_j6s": "japan-6-step", "tunic": "tunic",
    "metal_shoes": "metal", "leather_shoes": "leather", "metal_gloves": "metal",
    "leather_gloves": "leather",
}

# Choice layers: id -> probability of "no choice" when randomising.
# None = a choice is required; "equal" = "none" weighs the same as each option.
CHOICE_LAYERS = {
    "race": None,
    "hair": "equal",
    "facial-hair": 1.0,
    "eyelashes": 0.5,
    "headwear": 0.5,
    "ears-&-horns": 0.5,
    "jaw": 1.0,
    "shoes": 0.5,
    "clothes": 0.0,
    "gloves": 0.5,
}

DRAW_ORDER = [
    "race", "shoes", "clothes", "gloves", "jaw", "hair", "facial-hair",
    "eyes", "eyelashes", "headwear", "ears-&-horns", "weapon-overlay",
]


class Style:
    def __init__(self, zip_name="PUNY_CHARACTERS_v2.1_tdsm-2026.zip"):
        self.z = AssetZip(zip_name)
        self.ramps = {
            code: self.z.image(f"palettes/{code}-ramps.png")
            for code in self.csv("ramps")
        }
        self.choices = {}
        for layer in CHOICE_LAYERS:
            opts = []
            for element in self.csv(layer):
                code, _, tag = element.partition(":")
                if layer == "hair":
                    pairs = [("hair", "hair")]
                elif layer == "facial-hair":
                    pairs = [("hair", "facial_hair")]
                else:
                    pairs = RAMP_TAGS.get(tag, [])
                opts.append((code, pairs))
            self.choices[layer] = opts
        self._sheets = {}

    def csv(self, name):
        return [s.strip() for s in self.z.text(f"csv/{name}.csv").split(",") if s.strip()]

    def sheet(self, layer, asset):
        key = (layer, asset)
        if key not in self._sheets:
            self._sheets[key] = self.z.image(f"assets/{layer}/{asset}.png")
        return self._sheets[key]

    def random_recipe(self, rng, none_prob=None):
        none_prob = {**CHOICE_LAYERS, **(none_prob or {})}
        picks = {}
        for layer, opts in self.choices.items():
            p = none_prob[layer]
            codes = [c for c, _ in opts]
            if p is None:
                picks[layer] = rng.choice(codes)
            elif p == "equal":
                picks[layer] = rng.choice(codes + [None])
            else:
                picks[layer] = None if rng.random() < p else rng.choice(codes)
        swatches = {sel: rng.randrange(self.ramps[ramp].height)
                    for sel, ramp in SELECTIONS.items()}
        return {"picks": picks, "swatches": swatches}

    def recolour(self, img, pairs, swatches):
        """ramps_replace: map opaque reference colours to the selected swatch row."""
        if not pairs:
            return img
        table = {}
        for ramp_code, sel in pairs:
            ramp = self.ramps[ramp_code]
            row = swatches[sel]
            for x in range(ramp.width):
                ref = ramp.getpixel((x, 0))
                table.setdefault(ref, ramp.getpixel((x, row)))
        out = img.copy()
        px = out.load()
        for y in range(out.height):
            for x in range(out.width):
                c = px[x, y]
                if c[3] == 255 and c in table:
                    px[x, y] = table[c]
        return out

    def render(self, recipe):
        picks, swatches = recipe["picks"], recipe["swatches"]
        canvas = Image.new("RGBA", (DIM * FRAMES, DIM * len(DIRECTIONS)))
        for layer in DRAW_ORDER:
            if layer == "eyes":
                if picks["race"] != "human":
                    continue
                img = self.recolour(self.sheet("eyes", "eyes"), [("eyes", "eyes")], swatches)
            elif layer == "eyelashes" and picks["race"] != "human":
                continue
            elif layer == "weapon-overlay":
                img = self.sheet(layer, layer)
            else:
                code = picks[layer]
                if code is None:
                    continue
                pairs = dict(self.choices[layer])[code]
                img = self.recolour(self.sheet(layer, code), pairs, swatches)
            canvas.alpha_composite(img)
        return canvas


def frame(sheet, col, direction):
    row = DIRECTIONS.index(direction)
    return sheet.crop((col * DIM, row * DIM, (col + 1) * DIM, (row + 1) * DIM))


def anim_gif(sheet, anim, path, scale=4):
    """All 8 directions side by side, looping one animation."""
    cols, ticks = ANIMS[anim]
    frames = []
    for col in cols:
        strip = Image.new("RGBA", (DIM * len(DIRECTIONS), DIM))
        for i, d in enumerate(DIRECTIONS):
            strip.alpha_composite(frame(sheet, col, d), (i * DIM, 0))
        strip = strip.resize((strip.width * scale, strip.height * scale), Image.NEAREST)
        bg = Image.new("RGBA", strip.size, (58, 68, 102, 255))
        bg.alpha_composite(strip)
        frames.append(bg.convert("P", palette=Image.ADAPTIVE))
    frames[0].save(path, save_all=True, append_images=frames[1:], loop=0,
                   duration=[round(t * TICK_MS) for t in ticks], disposal=2)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("-n", type=int, default=8, help="how many characters")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("-o", "--out", default="out/characters")
    ap.add_argument("--none-prob", nargs="*", default=[], metavar="LAYER=P",
                    help="override a layer's chance of being empty")
    ap.add_argument("--scale", type=int, default=4)
    args = ap.parse_args()

    overrides = {}
    for item in args.none_prob:
        layer, _, p = item.partition("=")
        if layer not in CHOICE_LAYERS:
            ap.error(f"unknown layer {layer!r}")
        overrides[layer] = float(p)

    rng = random.Random(args.seed)
    style = Style()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    idles = []
    for i in range(args.n):
        recipe = style.random_recipe(rng, overrides)
        sheet = style.render(recipe)
        name = f"char_{i:03d}"
        sheet.save(out / f"{name}_sheet.png")
        (out / f"{name}.json").write_text(json.dumps(recipe, indent=2))
        anim_gif(sheet, "walk", out / f"{name}_walk.gif", args.scale)
        idles.append(frame(sheet, 0, "S"))
        print(name, {k: v for k, v in recipe["picks"].items() if v})

    # contact sheet of everyone's south-facing idle pose
    per_row = min(8, len(idles))
    rows = -(-len(idles) // per_row)
    grid = Image.new("RGBA", (per_row * DIM, rows * DIM), (58, 68, 102, 255))
    for i, im in enumerate(idles):
        grid.alpha_composite(im, ((i % per_row) * DIM, (i // per_row) * DIM))
    grid.resize((grid.width * args.scale, grid.height * args.scale), Image.NEAREST) \
        .save(out / "lineup.png")


if __name__ == "__main__":
    main()
