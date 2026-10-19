"""Import the horse from Single Head Games' Animal Farm Project Sprite Pack (a private source package).

CLAUDE.md section 3 (private asset workflow): the pack lives in `private-assets/` (git-ignored; its terms do not
allow redistributing the original files). This step reads it in place and writes the sheet the game draws into
`game/assets/animals/` (committed, with provenance). If the pack is missing, nothing already imported is touched.

The art is drawn at three times the world's pixel density (docs/assets/ASSET_SCALING_STANDARD.md): each 96 px
cell is reduced by 1/3 with a box filter and a hard alpha cut (tools/assets/sheets.py), so the horse is about
27 px long beside a 24 px cow and a 14 px person. Horse.png holds 13 frames in a 4 x 4 grid, read left to right:
standing facing right, down, left, up (0-3); walking left (4-5), down (6-7), up (8-9); grazing facing left
(10-12). AnimalSprite's "farm" layout draws them (walking right is the left walk flipped).

    python3 tools/animal_farm.py      # also run by tools/import_game_assets.py
"""
import hashlib
import json
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools" / "assets"))
import sheets  # noqa: E402

PACKAGE = "Animal_Farm_Project_Sprite_Pack_1.0"
DEFAULT_DIR = REPO / "private-assets"
OUT = REPO / "game" / "assets" / "animals"
CELL = 96
FACTOR = 1.0 / 3.0
# game skin -> the pack's sheet
SHEETS = {"farm_horse": "Png/Horse.png"}


def package_path():
    folder = Path(os.environ.get("MML_PRIVATE_ASSETS") or DEFAULT_DIR)
    path = folder / PACKAGE
    return path if path.is_dir() else None


def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def import_sheets(record, pkg_path):
    src = sheets.Source(str(pkg_path.relative_to(REPO)) if REPO in pkg_path.parents else str(pkg_path))
    n = 0
    for skin, member in sorted(SHEETS.items()):
        img = sheets.scale_sheet(src.image(member), CELL, CELL, FACTOR, "box")
        path = OUT / ("%s.png" % skin)
        img.save(path)
        record(path, PACKAGE, member, "every 96 px cell reduced by 1/3 (box, alpha cut at 128) to 32 px frames")
        n += 1
    return n


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py."""
    path = package_path()
    if path is None:
        print("%s not found (MML_PRIVATE_ASSETS or %s): horse import skipped; files are left as they are" % (PACKAGE, DEFAULT_DIR))
        old = REPO / "game" / "assets" / "PROVENANCE.json"
        if old.exists():
            prov.extend(e for e in json.loads(old.read_text())["files"] if e.get("source") == PACKAGE)
        return 0
    n = import_sheets(record, path)
    print("imported %d sheets from %s" % (n, path.name))
    return n


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    prov = [e for e in doc["files"] if e.get("source") != PACKAGE]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member,
                     "transform": how, "sha256": _sha(dest)})

    if package_path() is None:
        import_into([], record)
        return
    import_into(prov, record)
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")


if __name__ == "__main__":
    main()
