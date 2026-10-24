"""Import the market shelves from Craftpix's Free Pixel Art Dungeon Objects Asset Pack (a private source package).

GP-MARKET-SHELVES (owner directives 2026-10-24, docs/directives/2026-10-24_build21_craftpix_market_stalls.md and
2026-10-24_build21_final_execution.md). CLAUDE.md section 3 (private asset workflow): the zip lives in `private-assets/`
(git-ignored; the Craftpix file licence, craftpix.net/file-licenses, allows use and modification in a game that may be
sold, but not redistributing the art on its own, nor any AI training or generative use). This step reads it in place
with ordinary pixel operations and writes only the two shelves the game draws, into `game/assets/props/` (committed,
with provenance). If the zip is missing, nothing already imported is touched.

The source is `PNG/supplies_objects.png` (208 x 592). The two approved shelves are the EMPTY two-shelf units at the far
left of the first two shelving rows, found from the sheet's own transparency (the opaque bounds below; every other unit
in those rows is stocked):
    A (light wood)  x 2..46, y 12..54   (45 x 43)
    B (dark wood)   x 2..46, y 76..118  (45 x 43)
Cross-checked with `PSD/supplies_objects.psd`: a 240 x 592 canvas whose content lies 16 px further right (its layers
start at x 16; layer "wood_light" at y 12, as A's top row).

Modular extension (no stretching): a shelf's columns 8..11 are one repeat of the boards' vertical planks (the columns
4..38 repeat with a period of 4). EXTRA copies of those four columns are put in after column 11, so the boards, the top
rail and the base grow by whole planks and the posts, ends and outlines stay as drawn: 45 + 4 x EXTRA px wide. With
EXTRA = 2 (53 px), each board holds five 8 px goods side by side (ten in all).

    python3 tools/craftpix_shelves.py      # also run by tools/import_game_assets.py
"""
import hashlib
import io
import json
import os
import zipfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
PACKAGE = "craftpix-net-218281-free-pixel-art-dungeon-objects-asset-pack.zip"
DEFAULT_DIR = REPO / "private-assets"
SHEET = "PNG/supplies_objects.png"
OUT = REPO / "game" / "assets" / "props"
SHELVES = {"market_shelf_light": (2, 12, 47, 55), "market_shelf_dark": (2, 76, 47, 119)}     # crop boxes (x0, y0, x1, y1), x1/y1 exclusive
REPEAT = (8, 12)          # the columns of one plank repeat, x0..x1 exclusive
EXTRA = 2                 # repeats added in the middle


def package_path():
    folder = Path(os.environ.get("MML_PRIVATE_ASSETS") or DEFAULT_DIR)
    path = folder / PACKAGE
    return path if path.is_file() else None


def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def extend(img, extra=EXTRA, repeat=REPEAT):
    """The shelf `img` made wider by `extra` copies of its plank repeat, put in after the repeat: pixels copied, none scaled."""
    x0, x1 = repeat
    w, h = img.size
    piece = img.crop((x0, 0, x1, h))
    out = Image.new("RGBA", (w + extra * (x1 - x0), h))
    out.paste(img.crop((0, 0, x1, h)), (0, 0))
    for k in range(extra):
        out.paste(piece, (x1 + k * (x1 - x0), 0))
    out.paste(img.crop((x1, 0, w, h)), (x1 + extra * (x1 - x0), 0))
    return out


def import_shelves(record, path):
    OUT.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path) as z:
        sheet = Image.open(io.BytesIO(z.read(SHEET))).convert("RGBA")
    assert sheet.size == (208, 592), sheet.size
    n = 0
    for name, box in SHELVES.items():
        part = sheet.crop(box)
        bb = part.getbbox()
        assert bb == (0, 0, part.width, part.height), (name, bb)      # the crop is exactly the shelf's opaque bounds
        out = extend(part)
        dest = OUT / f"{name}.png"
        out.save(dest)
        record(dest, PACKAGE, SHEET, "crop x %d..%d, y %d..%d (the empty two-shelf unit); widened by %d copies of columns %d..%d "
               "(one plank repeat) after column %d: %d x %d, no scaling" % (box[0], box[2] - 1, box[1], box[3] - 1, EXTRA, REPEAT[0],
                                                                           REPEAT[1] - 1, REPEAT[1] - 1, out.width, out.height))
        n += 1
    return n


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py."""
    path = package_path()
    if path is None:
        print("%s not found (MML_PRIVATE_ASSETS or %s): market shelf import skipped; files are left as they are" % (PACKAGE, DEFAULT_DIR))
        old = REPO / "game" / "assets" / "PROVENANCE.json"
        if old.exists():
            prov.extend(e for e in json.loads(old.read_text())["files"] if e.get("source") == PACKAGE)
        return 0
    n = import_shelves(record, path)
    print("imported %d market shelves from %s" % (n, path.name))
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
