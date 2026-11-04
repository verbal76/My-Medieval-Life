"""Import the art for B25R1-Q3's water (owner decision 2026-11-03 and directive B25R1-017: winding streams and rivers with grassy
banks, rocks and shallows, flowing water, waterfalls at real drops into foaming pools, bridges where routes cross; owner
EA-01, store quality: water that reads as flowing, not rain; taller falls with foam; bridges with rails and decks).

The asset pipeline (.claude/skills/asset-integration-pipeline, CLAUDE.md section 3): art enters the game only through an
import step that records its source. The overworld's grass and cliffs are the free Puny World tileset's "overworld" corner
wangset, so its water comes from the same tileset and set, for one look (the Forgotten Memories water, also owned, has rock
shores in another palette and a 32 px grid: it would not sit beside this grass; docs/assets/packs.json). This step writes
game/assets/tiles/water_tiles.png, FRAMES (8) columns (animation frames, left to right; their length is water.json
"frame_seconds") by ROWS rows, 16 px tiles, 1:1:

    rows v * 160 + f * 16 + k  for look v 0-1, flow f 0-9 and water corners k 0-15 (bit 0 top-left, 1 top-right, 2
                     bottom-right, 3 bottom-left): the grass/river corner tile of the "overworld" wangset (PUNY_WORLD_v1.zip,
                     punyworld-overworld-tiles.tsx) for those corners, its open water (the set's water colour) moving:
                     f 0 still: the tile's own four-frame Tiled animation, each frame held twice (the slow shimmer of a pool);
                     f 1-8 flowing E, SE, S, SW, W, NW, N, NE: three long, soft ripples in the set's own lighter water
                     colours, drawn along the flow and scrolled STEP (2) px a frame downstream (16 px in eight frames:
                     seamless);
                     f 9 foaming: flecks of the set's foam colours drifting south (the pool below a waterfall).
                     The two looks differ in where the ripples lie (the generator picks one per cell, so no lattice shows),
                     and look 1 sets a tuft of the set's bank grass over the step of a corner tile (one or three corners
                     wet), softening the stair-stepped shore. k 0, 5 and 10 are left empty (the set has none).
    ROW["fall"]      the waterfall (the cliff's rim): the tileset's animated falling water between rocks (tiles 598-601),
                     its splash replaced by more cascade so the fall runs on into the cell below
    ROW["fall_foot"] the foot of a fall: open water with the fall's lower cascade and its splash, foam below
    ROW["ford"]      a ford: the still full-water tile's frames with the tileset's small flat stones (tile 703) set in twice
    ROW[bridge]      the bridges, the tileset's own walks as drawn (BRIDGE): the wooden walk with its rails (north-south:
                     723 north end, 750, 777 south end on its legs; east-west: 875 west end, 876, 877 east end) and the
                     castle wall-walk with crenellated parapets both sides (747 north-south, 775 east-west)

Drawn by OverworldView (MapView atlas 9, its still twin 10). Values: overworld_tiles.json "water" (tools/build_overworld_tiles.py, which takes
this layout from ROW, FRAMES, LOOKS).

    python3 tools/water_tiles.py      # also run by tools/import_game_assets.py
"""
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
DEST = REPO / "game" / "assets" / "tiles" / "water_tiles.png"
FREE_COLS = 27
FALL = [598, 599, 600, 601]
PEBBLES = 703                 # the free tileset's small flat stones: stepping stones on a ford
GRASS, RIVER = 1, 7
FRAMES = 8
LOOKS = 2
FLOWS = 10
EXTRA = LOOKS * FLOWS * 16    # the first row after the water: the waterfall
# the free tileset's walks: wooden (with rails, the south end on legs in the water) and the castle wall-walk (parapets)
BRIDGE = {"plank_ns": 750, "plank_ew": 876, "stone_ns": 747, "stone_ew": 775,
          "plank_n": 723, "plank_s": 777, "plank_w": 875, "plank_e": 877}
ROW = {"fall": EXTRA, "fall_foot": EXTRA + 1, "ford": EXTRA + 2}
for _i, _k in enumerate(BRIDGE):
    ROW[_k] = EXTRA + 3 + _i
ROWS = EXTRA + 3 + len(BRIDGE)
OPEN = (4, 160, 180)          # the set's open-water colour (measured: every pixel of the full-water tile 305)
RIPPLE = [(21, 174, 185), (35, 192, 191)]   # its lighter water colours (the shore's), the ripples
FOAM = [(29, 204, 203), (19, 219, 218), (236, 250, 248)]
TUFT = [(106, 112, 66), (133, 166, 67), (159, 183, 71)]   # the set's bank grass: shadow, grass, light (measured in its tiles)
DIRS = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]   # flow 1-8
STEP = 2                      # px a frame the ripples move (16 / FRAMES: one seamless loop)


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


def _h(x, y, salt):
    v = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    return (v ^ (v >> 13)) % 1000


def _ripples(d, look):
    """A 16 x 16 ripple pattern for flow direction d (dx, dy), on the torus: three long, soft streaks along the flow (a
    5 px line, a 3 px line beside it, a lighter head), spaced apart so they read as current, not rain."""
    pat = {}
    side = (-d[1], d[0])
    for n in range(3):
        x0 = (_h(n, 1, 7 + look) % 4) * 4 + n * 5
        y0 = (_h(n, 2, 7 + look) % 4) * 4 + n * 7
        for t in range(5):
            pat[((x0 + d[0] * t) % 16, (y0 + d[1] * t) % 16)] = RIPPLE[0]
        for t in range(1, 4):
            pat[((x0 + side[0] + d[0] * t) % 16, (y0 + side[1] + d[1] * t) % 16)] = RIPPLE[0]
        pat[((x0 + d[0] * 5) % 16, (y0 + d[1] * 5) % 16)] = RIPPLE[1]
    return pat


def _flowing(tile, d, frame, look):
    """The tile's open water replaced by the ripples, scrolled STEP px a frame along d (16 px in FRAMES: a seamless loop)."""
    out = tile.copy()
    pat = _ripples(d, look)
    for y in range(16):
        for x in range(16):
            if tile.getpixel((x, y))[:3] != OPEN:
                continue
            src = ((x - d[0] * STEP * frame) % 16, (y - d[1] * STEP * frame) % 16)
            out.putpixel((x, y), pat.get(src, OPEN) + (255,))
    return out


def _foaming(tile, frame, look):
    out = tile.copy()
    for y in range(16):
        for x in range(16):
            sy = (y - STEP * frame) % 16
            if tile.getpixel((x, y))[:3] == OPEN and _h(x, sy, 40 + look) < 55:
                out.putpixel((x, y), FOAM[_h(x, sy, 60 + look) % 3] + (255,))
    return out


def _tuft(tile, k, look):
    """Look 1: a tuft of bank grass over the step of a corner tile (one or three corners wet), where the shore turns."""
    n = bin(k).count("1")
    if look != 1 or n not in (1, 3):
        return tile
    # the tuft stands on the bank where the shore turns: the land pixel next to the water nearest the tile's centre (the
    # tile's own drawing decides, whatever its corner art), kept 2 px inside the tile
    def wet(x, y):
        r, g, b, _ = tile.getpixel((x, y))
        return b > r + 40 and b > g - 10
    best = None
    for y in range(2, 14):
        for x in range(2, 14):
            if not wet(x, y) and any(wet(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                d = (x - 7.5) ** 2 + (y - 7.5) ** 2
                if best is None or d < best[0]:
                    best = (d, x, y)
    if best is None:
        return tile
    cx, cy = best[1], best[2]
    out = tile.copy()
    shape = {(-2, 0): 1, (-1, -1): 2, (-1, 0): 1, (0, -2): 2, (0, -1): 1, (0, 0): 0, (1, -1): 2, (1, 0): 1, (2, 0): 0,
             (-1, 1): 0, (0, 1): 0, (1, 1): 0}
    for (dx, dy), c in shape.items():
        out.putpixel((cx + dx, cy + dy), TUFT[c] + (255,))
    return out


def _fall_top(fall):
    """The rim's fall with its splash replaced by more cascade (rows 6-9 again), so it runs on into the foot below."""
    out = fall.copy()
    out.paste(fall.crop((0, 6, 16, 10)), (0, 12))
    return out


def _fall_foot(water, fall, frame):
    """The foot of a fall: open water, the fall's cascade (its columns 3-12) coming down, its splash, foam below."""
    out = water.copy()
    out.paste(fall.crop((3, 6, 13, 12)), (3, 0))
    out.paste(fall.crop((2, 12, 14, 16)), (2, 6))
    for y in range(10, 16):
        for x in range(16):
            sy = (y - STEP * frame) % 16
            if out.getpixel((x, y))[:3] == OPEN and _h(x, sy, 90) < 260 - (y - 10) * 35:
                out.putpixel((x, y), FOAM[_h(x, sy, 91) % 3] + (255,))
    return out


def build(free, tiles, anims):
    sheet = Image.new("RGBA", (16 * FRAMES, 16 * ROWS), (0, 0, 0, 0))
    full = None
    for k in range(16):
        key = tuple(RIVER if k >> b & 1 else GRASS for b in range(4))
        ids = sorted(tiles.get(key, []))
        if k == 0 or not ids:
            continue
        frames = anims.get(ids[0], [ids[0]])
        base = _tile(free, FREE_COLS, ids[0])
        if k == 15:
            full = (base, frames)
        for look in range(LOOKS):
            r0 = look * FLOWS * 16
            for f in range(FRAMES):
                still = _tile(free, FREE_COLS, frames[(f // 2) % len(frames)])
                sheet.paste(_tuft(still, k, look), (f * 16, (r0 + k) * 16))
                for flow in range(1, 9):
                    sheet.paste(_tuft(_flowing(base, DIRS[flow - 1], f, look), k, look), (f * 16, (r0 + flow * 16 + k) * 16))
                sheet.paste(_tuft(_foaming(base, f, look), k, look), (f * 16, (r0 + 9 * 16 + k) * 16))
    base, frames = full
    peb = _tile(free, FREE_COLS, PEBBLES)
    for f in range(FRAMES):
        fall = _tile(free, FREE_COLS, FALL[f % 4])
        sheet.paste(_fall_top(fall), (f * 16, ROW["fall"] * 16))
        sheet.paste(_fall_foot(base, fall, f), (f * 16, ROW["fall_foot"] * 16))
        ford = _tile(free, FREE_COLS, frames[(f // 2) % len(frames)])
        ford.alpha_composite(peb.crop((3, 3, 16, 16)), (0, 0))
        ford.alpha_composite(peb, (4, 4))
        sheet.paste(ford, (f * 16, ROW["ford"] * 16))
        for name, t in BRIDGE.items():
            sheet.paste(_tile(free, FREE_COLS, t), (f * 16, ROW[name] * 16))
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
    DEST.parent.mkdir(parents=True, exist_ok=True)
    build(free.convert("RGBA"), tiles, anims).save(DEST)
    record(DEST, pwt.ZIP, pwt.TSX + " grass/river corner tiles and their animations, tiles 598-601 (falls), 703 (stones), "
           + ", ".join(str(t) for t in BRIDGE.values()) + " (the wooden walk and the castle wall-walk: bridges)",
           "B25R1-Q3/B25R1-017/EA-01 water tiles: %d animation frames x %d rows, 1:1 (rows look*160 + flow*16 + corners: the "
           "grass/river corner tiles, flow 0 their own animation held two frames each, 1-8 three long soft ripples (the set's "
           "lighter water colours) scrolled %d px a frame downstream, 9 drifting foam; look 1 other ripples and a tuft of the "
           "set's bank grass on corner steps; then the fall (its splash cut), the fall's foot (cascade, splash, foam), a ford "
           "(tile %d's stones twice in the full water) and the bridges, the tileset's walks as drawn)" % (FRAMES, ROWS, STEP, PEBBLES))
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
