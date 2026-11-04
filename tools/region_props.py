"""Write game/assets/tiles/region_props.png: the region's prop sheet (B25R1-018, owner B25R1-Q8: owned art now, the owner's pack
later), MapView atlas 8 (MapView.EXTRA_ATLASES: tile ids 800000 + index).

Rows 1-2 (index 8 + k): the chalk line of a hill figure, the free overworld tileset's dirt path tile for connection index k
(game/data/overworld_tiles.json dirt_path; 4-neighbour bits N1 E2 S4 W8) with its dirt recoloured to cut chalk (white, its
shading kept as light grey) and its grass untouched, so a figure reads as a white line carved in the turf, not as sand.

Row 0: Shade's eight tombstones from Miniworld (MiniWorldSprites.zip, Miscellaneous/Tombstones.png, 16 x 16 each, the world's
pixel density, copied 1:1), for the churchyards. Later rows are kept for the owner's pack: a new piece is a row here and a stamp
in game/data/region_stamps.json (tools/build_region_stamps.py).

Run:  python3 tools/region_props.py      # also run by tools/import_game_assets.py
"""

import hashlib
import io
import json
import zipfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
DEST = REPO / "game" / "assets" / "tiles" / "region_props.png"
COLUMNS = 8
MINI_ZIP = "MiniWorldSprites.zip"
TOMBS = "MiniWorldSprites/Miscellaneous/Tombstones.png"     # 64 x 32: two rows of four


def _chalk(tile):
    px = tile.load()
    for y in range(16):
        for x in range(16):
            r, g, b, a = px[x, y]
            if a and r >= g:                      # dirt (brown) and its dark rim, not the grass
                lum = 0.3 * r + 0.59 * g + 0.11 * b
                v = int(max(150, min(246, 150 + (lum - 40) * 1.1)))
                px[x, y] = (v, v, max(0, v - 8), a)
    return tile


def build():
    tombs = Image.open(io.BytesIO(zipfile.ZipFile(REPO / MINI_ZIP).read(TOMBS))).convert("RGBA")
    out = Image.new("RGBA", (COLUMNS * 16, 3 * 16), (0, 0, 0, 0))
    for k in range(8):
        out.paste(tombs.crop(((k % 4) * 16, (k // 4) * 16, (k % 4) * 16 + 16, (k // 4) * 16 + 16)), (k * 16, 0))
    import sys
    sys.path.insert(0, str(REPO / "tools"))
    import puny_world_terrain as pwt
    from assetzip import AssetZip
    free = pwt.load(AssetZip(pwt.ZIP))[0].convert("RGBA")
    cols = free.width // 16
    ids = json.loads((REPO / "game" / "data" / "overworld_tiles.json").read_text())["dirt_path"]
    for k in range(16):
        t = int((ids[k] or ids[10])[0]) % 100000
        tile = _chalk(free.crop(((t % cols) * 16, (t // cols) * 16, (t % cols) * 16 + 16, (t // cols) * 16 + 16)))
        out.paste(tile, (((8 + k) % COLUMNS) * 16, ((8 + k) // COLUMNS) * 16))
    return out


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py. Returns the number of files written."""
    DEST.parent.mkdir(parents=True, exist_ok=True)
    build().save(DEST)
    record(DEST, MINI_ZIP + " + PUNY_WORLD_v1.zip", TOMBS + "; the free overworld tileset's dirt path tiles",
           "the eight 16 x 16 tombstones copied 1:1 into row 0 of an 8-column prop sheet (MapView atlas 8); rows 1-2 the 16 dirt "
           "path tiles (overworld_tiles.json dirt_path) with the dirt recoloured to cut chalk, the grass kept (hill figures)")
    return 1


def _sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    mine = "assets/tiles/region_props.png"
    prov = [e for e in doc["files"] if e["file"] != mine]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member, "transform": how,
                     "sha256": _sha(dest)})

    import_into([], record)
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")
    print(f"wrote {DEST.relative_to(REPO)}")


if __name__ == "__main__":
    main()
