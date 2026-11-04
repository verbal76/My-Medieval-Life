"""Import the B25R1-Q8 tile sheets (owner decision 2026-11-03) as map atlases: Larchrow's Village & Cave Expansion and
Bow.Pixel's Low Grass Set.

CLAUDE.md section 3 (private asset workflow): both packages live in `private-assets/` (git-ignored; their terms allow use in
a commercial game, modified or not, but not redistributing the files as they are). This step reads them in place and writes
only the game's copies of the sheets, each one 1:1 (they are drawn on the world's own 16 px grid, ASSET_SCALING_STANDARD
section 1), unchanged, into `game/assets/tiles/` (committed, with provenance). A package missing on this machine leaves the
files already imported as they are.

    game/assets/tiles/larchrow_village_cave.png   Tilesheets/larchrow_village_cave_16x16.png (256 x 176: 16 columns x 11 rows),
                                                  MapView atlas 5: tile value 500000 + Larchrow's tile_id (= row * 16 + column);
                                                  the names are in docs/assets/LARCHROW_TILES.md (from the pack's tile_index.csv)
    game/assets/tiles/low_grass_1.png             BowPixel_Low_Grass/low_grass_1.png (320 x 320: 20 x 20 tufts), atlas 6: 600000 + id
    game/assets/tiles/low_grass_2.png             BowPixel_Low_Grass/low_grass_2.png, atlas 7: 700000 + id

    python3 tools/village_tile_sheets.py      # also run by tools/import_game_assets.py
"""
import hashlib
import io
import json
import os
import zipfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
DEFAULT_DIR = REPO / "private-assets"
OUT = REPO / "game" / "assets" / "tiles"
LARCHROW = "larchrow-village-cave-tileset.zip"
LARCHROW_SHEET = "larchrow-village-cave-tileset/Tilesheets/larchrow_village_cave_16x16.png"
GRASS = "BowPixel_Low_Grass"
GRASS_SHEETS = ["low_grass_1.png", "low_grass_2.png"]
SOURCES = (LARCHROW, GRASS)


def _folder():
    return Path(os.environ.get("MML_PRIVATE_ASSETS") or DEFAULT_DIR)


def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def _keep(prov, source):
    old = REPO / "game" / "assets" / "PROVENANCE.json"
    if old.exists():
        prov.extend(e for e in json.loads(old.read_text())["files"] if e.get("source") == source)


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py. Returns the number of sheets written."""
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    zp = _folder() / LARCHROW
    if zp.is_file():
        with zipfile.ZipFile(zp) as z:
            data = z.read(LARCHROW_SHEET)
        img = Image.open(io.BytesIO(data))
        assert img.size == (256, 176), img.size
        dest = OUT / "larchrow_village_cave.png"
        dest.write_bytes(data)
        record(dest, LARCHROW, LARCHROW_SHEET, "copied unchanged (16 x 16 tiles, 16 columns: MapView atlas 5)")
        n += 1
    else:
        print("%s not found (MML_PRIVATE_ASSETS or %s): Larchrow import skipped; files are left as they are" % (LARCHROW, DEFAULT_DIR))
        _keep(prov, LARCHROW)
    gd = _folder() / GRASS
    if gd.is_dir():
        for i, name in enumerate(GRASS_SHEETS):
            data = (gd / name).read_bytes()
            img = Image.open(io.BytesIO(data))
            assert img.size == (320, 320), (name, img.size)
            dest = OUT / name
            dest.write_bytes(data)
            record(dest, GRASS, name, "copied unchanged (16 x 16 tufts, 20 columns: MapView atlas %d)" % (6 + i))
            n += 1
    else:
        print("%s not found: low grass import skipped; files are left as they are" % GRASS)
        _keep(prov, GRASS)
    return n


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    prov = [e for e in doc["files"] if e.get("source") not in SOURCES]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member,
                     "transform": how, "sha256": _sha(dest)})

    print("imported %d sheets" % import_into(prov, record))
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")


if __name__ == "__main__":
    main()
