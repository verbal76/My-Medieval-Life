"""Import fruit-tree art from Craftpix's Free Pixel Art Plants for Farm (a private source package).

CLAUDE.md section 3 (private asset workflow): the zip lives in `private-assets/` (git-ignored; Craftpix's
licence does not allow redistributing the files). This step reads it in place and writes the files the
game needs into `game/assets/trees/` and `game/assets/icons/` (committed, with provenance), with the
fruit-tree variants in `game/assets/trees/fruit_trees.json` (mml-trees-art/1, merged with Living Forest's
trees.json by Trees.art()). If the zip is missing, nothing already imported is touched.

The art is drawn at the world's pixel density (docs/assets/ASSET_SCALING_STANDARD.md): used 1:1. Plants.png
holds every plant twice, on soil (left half) and on grass (right half); the grass versions are used. A fruit
tree's row has five stages left to right: seedling, small, medium, large, large in fruit. They become the
tree model's stages (tools/living_forest.py): sapling, young, growing, mature, plus `fruit` (the mature tree
with ripe fruit, drawn while its fruit hangs). The pack has no stump or cut art: the stump is the mature
tree's foot (its lowest rows) and the cut marks are small notches drawn here, both recorded as such.

    python3 tools/craftpix_plants.py      # also run by tools/import_game_assets.py
"""
import hashlib
import json
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools" / "assets"))
import sheets  # noqa: E402

PACKAGE = "craftpix-net-200380-free-pixel-art-plants-for-farm.zip"
DEFAULT_DIR = REPO / "private-assets"
SHEET = "PNG/Plants.png"
OUT = REPO / "game" / "assets" / "trees"
ICONS = REPO / "game" / "assets" / "icons"
# variant id -> (the row's band in Plants.png: y0, y1), the grass half starts at x 505
FRUIT_TREES = {"apple_orchard": (145, 212)}
GRASS_X = 505
STAGES = ["sapling", "young", "growing", "mature", "fruit"]
STUMP_ROWS = 10                 # the mature tree's lowest rows make the stump
SAPLING_ICON = {"apple_sapling": "apple_orchard"}
DRAWN = "(drawn by tools/craftpix_plants.py)"


def package_path():
    folder = Path(os.environ.get("MML_PRIVATE_ASSETS") or DEFAULT_DIR)
    path = folder / PACKAGE
    return path if path.is_file() else None


def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def tree_stages(sheet, band):
    """The five stage images of a fruit tree row, left to right, each cropped to its pixels."""
    y0, y1 = band
    row = sheet.crop((GRASS_X, y0, sheet.width, y1))
    boxes = [b for b in sheets.find_objects(row) if b[2] - b[0] >= 12 and b[3] - b[1] >= 14]
    boxes.sort(key=lambda b: b[0])
    if len(boxes) != len(STAGES):
        raise SystemExit("craftpix_plants: expected %d stages in the row at y %d-%d, found %d" % (len(STAGES), y0, y1, len(boxes)))
    return [(row.crop(b), (GRASS_X + b[0], y0 + b[1], GRASS_X + b[2], y0 + b[3])) for b in boxes]


def _pivot(img):
    """The trunk base: the bottom centre, a few pixels up into the grass patch under the tree."""
    return [img.width // 2, img.height - 4]


def _notch(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, size - 1, size - 1], fill=(58, 34, 24, 255))
    if size > 2:
        d.point((size // 2, size // 2), fill=(176, 132, 86, 255))
    return img


def import_trees(record, pkg_path):
    src = sheets.Source(str(pkg_path.relative_to(REPO)) if REPO in pkg_path.parents else str(pkg_path))
    sheet = src.image(SHEET)
    art = json.loads((OUT / "trees.json").read_text())         # for the leaves, which come from Living Forest
    out = {"format": "mml-trees-art/1", "note": "Fruit-tree art from Craftpix's Free Pixel Art Plants for Farm, used 1:1 by tools/craftpix_plants.py; merged with trees.json by Trees.art(). `fruit` is the mature tree drawn while its fruit hangs.", "variants": {}}
    written = 0
    for vid, band in FRUIT_TREES.items():
        stages = tree_stages(sheet, band)
        v = {"species": vid.split("_")[0], "season": "summer", "sizes": {}, "fruit_tree": True}
        files = {}
        for name, (img, box) in zip(STAGES, stages):
            path = OUT / ("%s_%s.png" % (vid, name))
            img.save(path)
            record(path, PACKAGE, SHEET, "crop %s (stage %s, the grass half), used 1:1" % (list(box), name))
            files[name] = (img, path.name)
            written += 1
        for name in ("young", "growing", "mature"):
            img, f = files[name]
            v["sizes"][name] = {"file": f, "w": img.width, "h": img.height, "pivot": _pivot(img)}
        img, f = files["fruit"]
        v["fruit"] = {"file": f, "w": img.width, "h": img.height, "pivot": _pivot(img)}
        sap, f = files["sapling"]
        v["sapling"] = {"file": f, "w": sap.width, "h": sap.height, "pivot": [sap.width // 2, sap.height]}
        mature, mf = files["mature"]
        pivot = _pivot(mature)
        v["pivot"] = pivot
        v["top"] = {"file": mf, "off": [0, 0], "w": mature.width, "h": mature.height}
        foot = mature.crop((0, mature.height - STUMP_ROWS, mature.width, mature.height))
        box = foot.getbbox()
        stump = foot.crop(box)
        path = OUT / ("%s_stump.png" % vid)
        stump.save(path)
        record(path, PACKAGE, SHEET, "the mature stage's lowest %d rows, cropped to its pixels (the pack has no stump)" % STUMP_ROWS)
        v["stump"] = {"file": path.name, "off": [box[0], mature.height - STUMP_ROWS + box[1]], "w": stump.width, "h": stump.height}
        written += 1
        v["cuts"] = {"left": [], "right": []}
        for side, dx in (("left", -3), ("right", 1)):
            for n in (1, 2, 3):
                size = n + 1
                path = OUT / ("%s_cut_%s_%d.png" % (vid, side, n))
                _notch(size).save(path)
                record(path, "", DRAWN, "a %d px trunk notch (the pack has no cut marks)" % size)
                v["cuts"][side].append({"file": path.name, "off": [pivot[0] + dx, pivot[1] - 7 - n // 2], "w": size, "h": size})
                written += 1
        v["leaves"] = list(art["variants"]["oak_summer"]["leaves"])        # Living Forest's leaves fall from it too
        out["variants"][vid] = v
    path = OUT / "fruit_trees.json"
    path.write_text(json.dumps(out, indent=1, sort_keys=False) + "\n")
    record(path, PACKAGE, "(generated)", "tools/craftpix_plants.py: what each fruit-tree file is, its size, offset and pivot")
    written += 1
    for item, vid in SAPLING_ICON.items():
        sap = Image.open(OUT / ("%s_sapling.png" % vid)).convert("RGBA")
        scale = min(1.0, 16 / sap.width, 16 / sap.height)
        icon = sap if scale == 1.0 else sap.resize((max(1, round(sap.width * scale)), max(1, round(sap.height * scale))), Image.NEAREST)
        cell = Image.new("RGBA", (16, 16))
        cell.alpha_composite(icon, ((16 - icon.width) // 2, 16 - icon.height))
        path = ICONS / ("%s.png" % item)
        cell.save(path)
        record(path, PACKAGE, SHEET, "the %s seedling, fitted into a 16 px icon cell (bottom centre)" % vid)
        written += 1
    return written


def import_into(prov, record):
    """Entry point for tools/import_game_assets.py (after the Living Forest step, which writes trees.json)."""
    path = package_path()
    if path is None:
        print("%s not found (MML_PRIVATE_ASSETS or %s): fruit-tree import skipped; files are left as they are" % (PACKAGE, DEFAULT_DIR))
        old = REPO / "game" / "assets" / "PROVENANCE.json"
        if old.exists():
            keep = [e for e in json.loads(old.read_text())["files"] if e.get("source") == PACKAGE or e.get("member") == DRAWN]
            prov.extend(keep)
        return 0
    n = import_trees(record, path)
    print("imported %d fruit-tree files from %s" % (n, path.name))
    return n


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    prov = [e for e in doc["files"] if e.get("source") != PACKAGE and e.get("member") != DRAWN]

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
