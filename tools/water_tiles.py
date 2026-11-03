"""Import the art for B25R1-Q3's water (owner decision 2026-11-03 and directive B25R1-017: winding streams and rivers with grassy
banks, rocks and shallows, flowing water, waterfalls at real drops into foaming pools, bridges where routes cross).

The asset pipeline (.claude/skills/asset-integration-pipeline, CLAUDE.md section 3): art enters the game only through an
import step that records its source. The overworld's grass and cliffs are the free Puny World tileset's "overworld" corner
wangset, so its water comes from the same tileset and set, for one look (the Forgotten Memories water, also owned, has rock
shores in another palette and a 32 px grid: it would not sit beside this grass; docs/assets/packs.json). This step writes
game/assets/tiles/water_tiles.png, 4 columns (animation frames, left to right, 0.15 s each in the game) by 166 rows, 16 px
tiles, 1:1:

    rows f * 16 + k  for flow f 0-9 and water corners k 0-15 (bit 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left):
                     the grass/river corner tile of the "overworld" wangset (PUNY_WORLD_v1.zip, punyworld-overworld-tiles.tsx)
                     for those corners, its open water (the set's water colour) moving:
                     f 0 still: the tile's own four-frame Tiled animation (the shimmer of a pool);
                     f 1-8 flowing E, SE, S, SW, W, NW, N, NE: a ripple pattern of the set's own lighter water colours
                     scrolled 4 px a frame that way, so the water visibly runs downstream (16 px in four frames: seamless);
                     f 9 foaming: white flecks of the set's foam colours over the water, a new pattern each frame (the
                     pool below a waterfall). k 0, 5 and 10 (no water; water on diagonal corners only: the set has none,
                     the generator never asks for them) are left empty.
    row 160          the waterfall: the tileset's animated falling water between rocks (tiles 598-601)
    row 161          plank bridge running north-south: the tileset's plank walk (tile 847), one frame repeated
    row 162          plank bridge running east-west: the tileset's plank walk (tile 876)
    row 163          stone bridge north-south: the paid Puny World tileset's flagstone ground (PUNY-WORLD-PAID_v1.zip, tile 10150)
                     with a low parapet (its own stone darkened) down both sides
    row 164          stone bridge east-west: the same with the parapet along the top and bottom
    row 165          a ford: the still full-water tile's frames with the tileset's small flat stones (tile 703) set in twice

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
PEBBLES = 703                 # the free tileset's small flat stones: stepping stones on a ford
PARAPET = 0.62
GRASS, RIVER = 1, 7
FRAMES = 4
FLOWS = 10
EXTRA = FLOWS * 16            # the first row after the water: the waterfall
ROWS = EXTRA + 6
OPEN = (4, 160, 180)          # the set's open-water colour (measured: every pixel of the full-water tile 305)
RIPPLE = [(21, 174, 185), (35, 192, 191)]   # its lighter water colours (the shore's), the ripples
FOAM = [(29, 204, 203), (19, 219, 218), (236, 250, 248)]
DIRS = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]   # flow 1-8


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


def _h(x, y, salt):
    v = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    return (v ^ (v >> 13)) % 1000


def _ripples(d):
    """A 16 x 16 ripple pattern for flow direction d (dx, dy), on the torus: short streaks along the flow."""
    pat = {}
    for n in range(7):
        x0, y0 = _h(n, 1, 7) % 16, _h(n, 2, 7) % 16
        col = RIPPLE[n % 2]
        for t in range(3 if n % 3 else 4):
            pat[((x0 + d[0] * t) % 16, (y0 + d[1] * t) % 16)] = col
    return pat


def _flowing(tile, d, frame):
    """The tile's open water replaced by the ripples, scrolled 4 px a frame along d (16 px in four frames: a seamless loop)."""
    out = tile.copy()
    pat = _ripples(d)
    for y in range(16):
        for x in range(16):
            if tile.getpixel((x, y))[:3] != OPEN:
                continue
            src = ((x - d[0] * 4 * frame) % 16, (y - d[1] * 4 * frame) % 16)
            out.putpixel((x, y), pat.get(src, OPEN) + (255,))
    return out


def _foaming(tile, frame):
    out = tile.copy()
    for y in range(16):
        for x in range(16):
            if tile.getpixel((x, y))[:3] == OPEN and _h(x, y, 40 + frame) < 60:
                out.putpixel((x, y), FOAM[_h(x, y, 60 + frame) % 3] + (255,))
    return out


def build(free, paid, tiles, anims):
    sheet = Image.new("RGBA", (16 * FRAMES, 16 * ROWS), (0, 0, 0, 0))
    for k in range(16):
        key = tuple(RIVER if k >> b & 1 else GRASS for b in range(4))
        ids = sorted(tiles.get(key, []))
        if k == 0 or not ids:
            continue
        frames = anims.get(ids[0], [ids[0]])
        base = _tile(free, FREE_COLS, ids[0])
        for f in range(FRAMES):
            sheet.paste(_tile(free, FREE_COLS, frames[f % len(frames)]), (f * 16, k * 16))
            for flow in range(1, 9):
                sheet.paste(_flowing(base, DIRS[flow - 1], f), (f * 16, (flow * 16 + k) * 16))
            sheet.paste(_foaming(base, f), (f * 16, (9 * 16 + k) * 16))
    for f in range(FRAMES):
        sheet.paste(_tile(free, FREE_COLS, FALL[f]), (f * 16, EXTRA * 16))
        sheet.paste(_tile(free, FREE_COLS, PLANK_NS), (f * 16, (EXTRA + 1) * 16))
        sheet.paste(_tile(free, FREE_COLS, PLANK_EW), (f * 16, (EXTRA + 2) * 16))
        st = _tile(paid, PAID_COLS, STONE)
        sheet.paste(_parapet(st, True), (f * 16, (EXTRA + 3) * 16))
        sheet.paste(_parapet(st, False), (f * 16, (EXTRA + 4) * 16))
        ford = sheet.crop((f * 16, 15 * 16, f * 16 + 16, 16 * 16))
        peb = _tile(free, FREE_COLS, PEBBLES)
        ford.alpha_composite(peb.crop((3, 3, 16, 16)), (0, 0))
        ford.alpha_composite(peb, (4, 4))
        sheet.paste(ford, (f * 16, (EXTRA + 5) * 16))
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
           "B25R1-Q3/B25R1-017 water tiles: 4 animation frames x %d rows, 1:1 (rows flow*16 + corners: the grass/river corner "
           "tiles, flow 0 their own animation, 1-8 the open water's ripples (the set's lighter water colours) scrolled 4 px a "
           "frame downstream, 9 foam flecks; then the waterfall, plank bridges, stone bridges (the flagstone with its edges "
           "darkened to %.2f) and a ford (the full water with tile %d's stones set in twice))" % (ROWS, PARAPET, PEBBLES))
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
