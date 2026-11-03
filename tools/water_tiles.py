"""Import the art for B25R1-Q3's streams (owner decision 2026-11-03: winding streams with grassy banks, rocks in the water,
waterfalls over cliff edges into pools, bridges where roads cross).

The asset pipeline (.claude/skills/asset-integration-pipeline, CLAUDE.md section 3): art enters the game only through an
import step that records its source. The overworld's grass and cliffs are the free Puny World tileset's "overworld" corner
wangset, so its water comes from the same tileset and set, for one look: this step writes game/assets/tiles/water_tiles.png,
4 columns (animation frames, left to right, 0.15 s each in the game) by 21 rows, 16 px tiles, 1:1:

    rows 0-15  the grass/river corner tiles of the "overworld" wangset (PUNY_WORLD_v1.zip, punyworld-overworld-tiles.tsx),
               row = the water corners (bit 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left), each with the four
               frames of its own Tiled animation; rows 0 (no water), 5 and 10 (water on diagonal corners only: the set has
               none, the generator never asks for them) are left empty
    row 16     the waterfall: the tileset's animated falling water between rocks (tiles 598-601)
    row 17     plank bridge running north-south: the tileset's narrow plank walk (tile 847), one frame repeated
    row 18     plank bridge running east-west: the tileset's plank walk (tile 876)
    row 19     stone bridge north-south: the paid Puny World tileset's flagstone ground (PUNY-WORLD-PAID_v1.zip, tile 10150) with
               a low parapet (its own stone darkened) down both sides
    row 20     stone bridge east-west: the same with the parapet along the top and bottom
    row 21     a ford: the full-water tile's frames with the tileset's small flat stones (tile 703) set in them twice,
               stepping stones across

Drawn by OverworldView (MapView atlas 5). Values: overworld_tiles.json "water" (tools/build_overworld_tiles.py).

    python3 tools/water_tiles.py      # also run by tools/import_game_assets.py
"""
import hashlib
import io
import json
import sys
import zipfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
DEST = REPO / "game" / "assets" / "tiles" / "water_tiles.png"
PAID_ZIP = "PUNY-WORLD-PAID_v1.zip"
PAID_SHEET = "PUNY-WORLD-PAID_v1/Tiled/punyworld-tiles.png"
PAID_COLS = 220
FREE_COLS = 27
FALL = [598, 599, 600, 601]
PLANK_NS = 847
PLANK_EW = 876
STONE = 10150
PARAPET = 0.62
GRASS, RIVER = 1, 7
FRAMES = 4
ROWS = 22
PEBBLES = 703                 # the free tileset's small flat stones: stepping stones on a ford


def _sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def _tile(img, cols, t):
    return img.crop(((t % cols) * 16, (t // cols) * 16, (t % cols) * 16 + 16, (t // cols) * 16 + 16))


def _animations(root):
    out = {}
    for t in root.iter("tile"):
        a = t.find("animation")
        if a is not None:
            out[int(t.get("id"))] = [int(f.get("tileid")) for f in a.findall("frame")]
    return out


def _parapet(stone, ns):
    out = stone.copy()
    for y in range(16):
        for x in range(16):
            edge = (x < 2 or x > 13) if ns else (y < 2 or y > 13)
            if edge:
                r, g, b, a = out.getpixel((x, y))
                out.putpixel((x, y), (int(r * PARAPET), int(g * PARAPET), int(b * PARAPET), 255))
    return out


def build(free, paid, tiles, anims):
    sheet = Image.new("RGBA", (16 * FRAMES, 16 * ROWS), (0, 0, 0, 0))
    for k in range(16):
        key = tuple(RIVER if k >> b & 1 else GRASS for b in range(4))
        ids = sorted(tiles.get(key, []))
        if k == 0 or not ids:
            continue
        frames = anims.get(ids[0], [ids[0]])
        for f in range(FRAMES):
            sheet.paste(_tile(free, FREE_COLS, frames[f % len(frames)]), (f * 16, k * 16))
    for f in range(FRAMES):
        sheet.paste(_tile(free, FREE_COLS, FALL[f]), (f * 16, 16 * 16))
        sheet.paste(_tile(free, FREE_COLS, PLANK_NS), (f * 16, 17 * 16))
        sheet.paste(_tile(free, FREE_COLS, PLANK_EW), (f * 16, 18 * 16))
        st = _tile(paid, PAID_COLS, STONE)
        sheet.paste(_parapet(st, True), (f * 16, 19 * 16))
        sheet.paste(_parapet(st, False), (f * 16, 20 * 16))
        ford = sheet.crop((f * 16, 15 * 16, f * 16 + 16, 16 * 16))
        peb = _tile(free, FREE_COLS, PEBBLES)
        ford.alpha_composite(peb.crop((3, 3, 16, 16)), (0, 0))
        ford.alpha_composite(peb, (4, 4))
        sheet.paste(ford, (f * 16, 21 * 16))
    return sheet


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py. Returns the number of files written."""
    import xml.etree.ElementTree as ET
    import puny_world_terrain as pwt
    from assetzip import AssetZip
    z = AssetZip(pwt.ZIP)
    free, _, ids, tiles, _ = pwt.load(z)
    assert ids["grass"] == GRASS and ids["river"] == RIVER
    anims = _animations(ET.fromstring(z.text(pwt.TSX)))
    paid = Image.open(io.BytesIO(zipfile.ZipFile(REPO / PAID_ZIP).read(PAID_SHEET))).convert("RGBA")
    DEST.parent.mkdir(parents=True, exist_ok=True)
    build(free.convert("RGBA"), paid, tiles, anims).save(DEST)
    record(DEST, pwt.ZIP + " + " + PAID_ZIP, pwt.TSX + " grass/river corner tiles and their animations, tiles 598-601, 847, 876; "
           + PAID_SHEET + " tile %d" % STONE,
           "B25R1-Q3 water tiles: 4 animation frames x 21 rows, 1:1 (rows 0-15 grass/river corners by water-corner bits, 16 "
           "waterfall, 17-18 plank bridges, 19-20 stone bridges: the flagstone with its edges darkened to %.2f, 21 a ford: the full "
           "water with tile %d's stones set in twice)" % (PARAPET, PEBBLES))
    return 1


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    mine = "assets/tiles/water_tiles.png"
    prov = [e for e in doc["files"] if e["file"] != mine]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member, "transform": how, "sha256": _sha(dest)})

    n = import_into([], record)
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")
    print("imported %d water tile sheet" % n)


if __name__ == "__main__":
    main()
