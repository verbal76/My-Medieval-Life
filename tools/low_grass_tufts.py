"""Choose which of Bow.Pixel's Low Grass tufts the game scatters on open grass (owner decision B25R1-Q8, 2026-11-03:
"Bow.Pixel Low Grass ... looks like this is our winner").

The two imported sheets (game/assets/tiles/low_grass_1.png and low_grass_2.png, MapView atlases 6 and 7, 20 x 20 tufts of
16 px each, imported unchanged by tools/import_game_assets.py) hold 800 low tufts: plain green blades, blades with small
flowers, and tufts with dark-outlined pebbles. Laid on the Puny World grass the dark outlines read as holes, so they are left
out (agent decision, looked at on a mock-up); the rest are sorted by their opaque pixels:

    plain     every opaque pixel green (hue 0.17-0.45, saturation and value over 0.3)
    flowered  no dark pixel (value under 0.3), some pixels not green (the flowers)

Writes game/data/low_grass.json (format mml-low-grass/1): the tile values (atlas * 100000 + row * 20 + column) of each kind,
sorted, read by MapView.grass_tuft. Deterministic: same sheets, same file.

    python3 tools/low_grass_tufts.py           # write it
    python3 tools/low_grass_tufts.py --check   # exit 1 if the file is out of date
"""
import colorsys
import json
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
SHEETS = [(6, REPO / "game" / "assets" / "tiles" / "low_grass_1.png"), (7, REPO / "game" / "assets" / "tiles" / "low_grass_2.png")]
DEST = REPO / "game" / "data" / "low_grass.json"
T = 16
COLS = 20


def classify(img: Image.Image, col: int, row: int) -> str:
    """'plain', 'flowered' or 'dark' for the tuft at (col, row)."""
    other = dark = 0
    for y in range(T):
        for x in range(T):
            r, g, b, a = img.getpixel((col * T + x, row * T + y))
            if a < 128:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if 0.17 < h < 0.45 and s > 0.3 and v > 0.3:
                continue
            if v < 0.3:
                dark += 1
            else:
                other += 1
    return "dark" if dark else "flowered" if other else "plain"


def build() -> dict:
    out = {"format": "mml-low-grass/1", "plain": [], "flowered": []}
    for atlas, path in SHEETS:
        img = Image.open(path).convert("RGBA")
        for row in range(img.height // T):
            for col in range(COLS):
                kind = classify(img, col, row)
                if kind in out:
                    out[kind].append(atlas * 100000 + row * COLS + col)
    return out


def main() -> int:
    text = json.dumps(build(), indent=1) + "\n"
    if "--check" in sys.argv:
        ok = DEST.exists() and DEST.read_text() == text
        print("low_grass.json up to date" if ok else "low_grass.json out of date: run tools/low_grass_tufts.py")
        return 0 if ok else 1
    DEST.write_text(text)
    d = json.loads(text)
    print(f"wrote {DEST.relative_to(REPO)}: {len(d['plain'])} plain, {len(d['flowered'])} flowered")
    return 0


if __name__ == "__main__":
    sys.exit(main())
