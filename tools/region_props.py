"""Write game/assets/tiles/region_props.png: the region's prop sheet (B25R1-018, owner B25R1-Q8: owned art now, the owner's pack
later), MapView atlas 8 (MapView.EXTRA_ATLASES: tile ids 800000 + index).

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


def build():
    tombs = Image.open(io.BytesIO(zipfile.ZipFile(REPO / MINI_ZIP).read(TOMBS))).convert("RGBA")
    out = Image.new("RGBA", (COLUMNS * 16, 16), (0, 0, 0, 0))
    for k in range(8):
        out.paste(tombs.crop(((k % 4) * 16, (k // 4) * 16, (k % 4) * 16 + 16, (k // 4) * 16 + 16)), (k * 16, 0))
    return out


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py. Returns the number of files written."""
    DEST.parent.mkdir(parents=True, exist_ok=True)
    build().save(DEST)
    record(DEST, MINI_ZIP, TOMBS, "the eight 16 x 16 tombstones copied 1:1 into row 0 of an 8-column prop sheet (MapView atlas 8)")
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
