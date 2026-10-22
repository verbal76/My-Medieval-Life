"""Import the art for B14-07's ways through a cliff (steps, wooden stairs, walkways) and the two new items' icons.

The asset pipeline (.claude/skills/asset-integration-pipeline, CLAUDE.md section 3): art enters the game only through an
import step that records its source. This step writes, into game/assets/terrain/ (one 16 x 16 tile per file, drawn by
OverworldView over a rim cell made passable) and game/assets/icons/:

    terrain/steps.png        Forgotten Memories (private-assets/ForgottenMemories.zip, TileSet.png): a 32 x 32 piece of
                             its laid-stone paving reduced 1/2 (box; an integer reduction, so a few stones show in one
                             world tile), with a darker line every 4 rows so the cut stone reads as steps. If the private zip is missing,
                             the file already imported is kept.
    terrain/walkway_ns.png   16x16 Miniworld (MiniWorldSprites.zip, Miscellaneous/Bridge.png): the middle 16 x 16 of the
    terrain/walkway_ew.png   north-south bridge's planks (frame 0) and of the east-west bridge's (frame 1), 1:1.
    terrain/stairs_ns.png    the same planks with a darker riser line every 4 rows (or columns), so a stair reads apart
    terrain/stairs_ew.png    from a walkway.
    icons/nails.png          16x16 Survival RPG Icons.zip: Metal/Metal-Nugget-03 (small grey pieces), copied unchanged.
    icons/mallet.png         16x16 Survival RPG Icons.zip: Tools/Hammer-15 (the wooden one), copied unchanged.

Every file is recorded in game/assets/PROVENANCE.json.

    python3 tools/terrain_art.py      # also run by tools/import_game_assets.py
"""
import hashlib
import io
import json
import os
import zipfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "game" / "assets" / "terrain"
ICONS = REPO / "game" / "assets" / "icons"
FM_PACKAGE = "ForgottenMemories.zip"
FM_DIR = REPO / "private-assets"
FM_SHEET = "TileSet.png"
FM_STONE = (1472, 608)                  # top-left of a 32 x 32 piece inside the laid-stone block (1440-1568, 576-704)
MW_ZIP = "MiniWorldSprites.zip"
MW_BRIDGE = "MiniWorldSprites/Miscellaneous/Bridge.png"
PLANKS = {"ns": (8, 12), "ew": (48, 20)}   # top-left of the 16 x 16 middle of each bridge frame
ICON_ZIP = "16x16 Survival RPG Icons.zip"
ICON_SRC = {"nails": "16x16 Survival RPG Icons/Metal/Metal-Nugget-03.png", "mallet": "16x16 Survival RPG Icons/Tools/Hammer-15.png"}
SHADOW = 0.62                           # a riser line's brightness


def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def fm_path():
    folder = Path(os.environ.get("MML_PRIVATE_ASSETS") or FM_DIR)
    path = folder / FM_PACKAGE
    return path if path.is_file() else None


def risers(tile, vertical):
    """A darker line every 4 rows (or columns with `vertical`): treads and risers."""
    out = tile.copy()
    px = out.load()
    for a in range(16):
        for b in range(3, 16, 4):
            x, y = (b, a) if vertical else (a, b)
            r, g, bl, al = px[x, y]
            px[x, y] = (int(r * SHADOW), int(g * SHADOW), int(bl * SHADOW), al)
    return out


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py. Returns the number of files written."""
    OUT.mkdir(parents=True, exist_ok=True)
    ICONS.mkdir(parents=True, exist_ok=True)
    n = 0
    bridge = Image.open(io.BytesIO(zipfile.ZipFile(REPO / MW_ZIP).read(MW_BRIDGE))).convert("RGBA")
    for run, (x, y) in PLANKS.items():
        tile = bridge.crop((x, y, x + 16, y + 16))
        dest = OUT / ("walkway_%s.png" % run)
        tile.save(dest)
        record(dest, MW_ZIP, MW_BRIDGE, "the 16 x 16 middle of frame %d's planks at (%d, %d), 1:1" % (0 if run == "ns" else 1, x, y))
        dest = OUT / ("stairs_%s.png" % run)
        risers(tile, run == "ew").save(dest)
        record(dest, MW_ZIP, MW_BRIDGE, "frame %d's planks at (%d, %d), 1:1, a riser line darkened to %.2f every 4 %s"
               % (0 if run == "ns" else 1, x, y, SHADOW, "columns" if run == "ew" else "rows"))
        n += 2
    icons = zipfile.ZipFile(REPO / ICON_ZIP)
    for item, member in ICON_SRC.items():
        dest = ICONS / ("%s.png" % item)
        dest.write_bytes(icons.read(member))
        record(dest, ICON_ZIP, member, "copied unchanged")
        n += 1
    path = fm_path()
    if path is None:
        print("%s not found: the steps tile is left as it is" % FM_PACKAGE)
        old = REPO / "game" / "assets" / "PROVENANCE.json"
        if old.exists():
            prov.extend(e for e in json.loads(old.read_text())["files"] if e.get("source") == FM_PACKAGE)
        return n
    sheet = Image.open(io.BytesIO(zipfile.ZipFile(path).read(FM_SHEET))).convert("RGBA")
    x, y = FM_STONE
    dest = OUT / "steps.png"
    risers(sheet.crop((x, y, x + 32, y + 32)).resize((16, 16), Image.BOX), False).save(dest)
    record(dest, FM_PACKAGE, FM_SHEET, "the 32 x 32 piece of the laid-stone paving at (%d, %d), reduced 1/2 (box), a step line darkened to %.2f every 4 rows" % (x, y, SHADOW))
    return n + 1


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    mine = {"assets/terrain/" + f for f in ["steps.png", "walkway_ns.png", "walkway_ew.png", "stairs_ns.png", "stairs_ew.png"]} | {"assets/icons/nails.png", "assets/icons/mallet.png"}
    prov = [e for e in doc["files"] if e["file"] not in mine]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member, "transform": how, "sha256": _sha(dest)})

    if fm_path() is None:
        keep = [e for e in doc["files"] if e["file"] == "assets/terrain/steps.png"]
        prov.extend(keep)
    n = import_into([], record)
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")
    print("imported %d terrain files" % n)


if __name__ == "__main__":
    main()
