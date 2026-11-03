"""Import the art for B25R1's road hierarchy (owner decision B25R1-Q1, 2026-11-03): stone roads and dirt trails beside the
dirt roads the overworld already draws.

The asset pipeline (.claude/skills/asset-integration-pipeline, CLAUDE.md section 3): art enters the game only through an
import step that records its source. This step writes one sheet, game/assets/tiles/road_tiles.png, 16 columns (one per set
of connected sides, the overworld's dirt_path index: bit 0 north, 1 east, 2 south, 3 west) by 6 rows:

    rows 0-3  stone road: each of the free Puny World tileset's dirt path tiles (PUNY_WORLD_v1.zip, its "pathways" wangset:
              the same tiles the overworld draws its roads with, overworld_tiles.json dirt_path), its dirt pixels replaced by
              the paid Puny World tileset's laid-stone paving (PUNY-WORLD-PAID_v1.zip, punyworld-tiles.png tiles 10150, 10151,
              10370 and 10371: a 2 x 2 block of the grey flagstone ground, one variant a row) and its dirt-to-grass rim darkened
              into a kerb. The grass round the road, the shape and the joins stay the path tile's own, so a stone road meets
              the grass and the dirt road like a road, not like a row of building blocks.
    rows 4-5  dirt trail: the same dirt path tiles narrowed by one ring (the dirt rim turned to the grass fringe, the fringe to
              grass) with tufts of grass growing through the dirt (2 x 2 pixel tufts by a fixed hash, two variants), so a trail reads as a worn
              footway.

Drawn by OverworldView at run time on the road cells RegionRoads.cell_kind classes "stone" or "trail" (atlas 4 of MapView,
tile value 400000 + row * 16 + index); every other road cell keeps its dirt path tile. Same cells, same walkability.

    python3 tools/road_tiles.py      # also run by tools/import_game_assets.py
"""
import hashlib
import io
import json
import zipfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
DEST = REPO / "game" / "assets" / "tiles" / "road_tiles.png"
OVERWORLD_TILES = REPO / "game" / "data" / "overworld_tiles.json"
PAID_ZIP = "PUNY-WORLD-PAID_v1.zip"
PAID_SHEET = "PUNY-WORLD-PAID_v1/Tiled/punyworld-tiles.png"
FREE_ZIP = "PUNY_WORLD_v1.zip"
FREE_SHEET = "PUNY_WORLD_v1/PUNY_WORLD_v1/punyworld-overworld-tileset.png"
STONE = [10150, 10151, 10370, 10371]          # the paid atlas's laid-stone (flagstone) ground, a 2 x 2 block
PAID_COLS = 220
FREE_COLS = 27
# the dirt path tiles' colours (measured): the dirt, its pebbles, the rim and the fringe into the grass
DIRT = {(196, 178, 83), (192, 171, 74), (183, 162, 72)}
RIM = (184, 175, 73)
FRINGE = (157, 167, 71)
GRASS = (133, 166, 67)
KERB = 0.74                                    # the stone road's rim: the stone darkened to this
TRAIL_GRASS = 22                               # percent of a trail's dirt pixels where grass grows through


def _sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def _tile(img, cols, t):
    return img.crop(((t % cols) * 16, (t // cols) * 16, (t % cols) * 16 + 16, (t // cols) * 16 + 16))


def _hash(x, y, salt):
    h = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    return (h ^ (h >> 13)) % 100


def build(paid, free, path_ids):
    """The sheet: rows 0-3 stone (one paving variant a row), rows 4-5 trail; columns by connection index."""
    sheet = Image.new("RGBA", (16 * 16, 16 * 6), (0, 0, 0, 0))
    for k in range(16):
        if not path_ids[k]:
            continue
        src = _tile(free, FREE_COLS, int(path_ids[k][0]) % 100000)
        for v, sid in enumerate(STONE):
            stone = _tile(paid, PAID_COLS, sid)
            out = src.copy()
            for y in range(16):
                for x in range(16):
                    c = src.getpixel((x, y))[:3]
                    s = stone.getpixel((x, y))
                    if c in DIRT:
                        out.putpixel((x, y), s)
                    elif c == RIM:
                        out.putpixel((x, y), (int(s[0] * KERB), int(s[1] * KERB), int(s[2] * KERB), 255))
            sheet.paste(out, (k * 16, v * 16))
        for v in range(2):
            out = src.copy()
            for y in range(16):
                for x in range(16):
                    c = src.getpixel((x, y))[:3]
                    if c == RIM:
                        out.putpixel((x, y), FRINGE + (255,))
                    elif c == FRINGE:
                        out.putpixel((x, y), GRASS + (255,))
                    elif c in DIRT and _hash(x // 2, y // 2, v * 16 + k) < TRAIL_GRASS:      # tufts of 2 x 2 pixels
                        out.putpixel((x, y), (FRINGE if _hash(x // 2, y // 2, 99 + v) < 50 else GRASS) + (255,))
            sheet.paste(out, (k * 16, (4 + v) * 16))
    return sheet


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py. Returns the number of files written."""
    paid = Image.open(io.BytesIO(zipfile.ZipFile(REPO / PAID_ZIP).read(PAID_SHEET))).convert("RGBA")
    import puny_world_terrain as pwt
    from assetzip import AssetZip
    free = pwt.load(AssetZip(pwt.ZIP))[0].convert("RGBA")
    path_ids = json.loads(OVERWORLD_TILES.read_text())["dirt_path"]
    DEST.parent.mkdir(parents=True, exist_ok=True)
    build(paid, free, path_ids).save(DEST)
    record(DEST, PAID_ZIP + " + " + FREE_ZIP, PAID_SHEET + " tiles " + ", ".join(map(str, STONE)) + "; " + pwt.TSX + " dirt pathways",
           "B25R1 road tiles: 16 dirt path tiles (overworld_tiles.json dirt_path) x 4 rows with their dirt replaced by the paid "
           "flagstone ground and the rim darkened to %.2f (stone road), x 2 rows narrowed by one ring with %d%% grass through "
           "the dirt (trail)" % (KERB, TRAIL_GRASS))
    return 1


def main():
    import sys
    sys.path.insert(0, str(REPO / "tools"))
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    mine = "assets/tiles/road_tiles.png"
    prov = [e for e in doc["files"] if e["file"] != mine]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member, "transform": how, "sha256": _sha(dest)})

    n = import_into([], record)
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")
    print("imported %d road tile sheet" % n)


if __name__ == "__main__":
    main()
