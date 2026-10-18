"""Import the tree art the game needs from the Living Forest Unity package (a private source package).

CLAUDE.md section 3 (private asset workflow): the package is not in the repository. It lives in
`private-assets/` (git-ignored); this step finds it through the environment variable
MML_PRIVATE_ASSETS (a folder) or the default `/home/user/My-Medieval-Life/private-assets`, reads the
sprites straight out of it, and writes the files the game needs into `game/assets/trees/` (committed,
with provenance in `game/assets/PROVENANCE.json`), so builds never need the package. If the package is
missing the step is skipped with a message and nothing already imported is touched.

The package is a gzip tar in Unity's layout: `<guid>/pathname` (the asset path), `<guid>/asset` (the
file) and `<guid>/asset.meta` (import settings: the sprite pivot). The art is 32 pixels per unit, top
down; the game's own art is 16 px, so every image is reduced to half size here (a 2 x 2 box average on
premultiplied colour, then alpha cut at half so the edges stay crisp) and the game draws it at scale 1
with nearest filtering.

What is imported, for each of five variants (oak in summer, autumn and snow; pine in summer and snow):

    <variant>_young.png   the pack's Small healthy tree        (growth stage YOUNG)
    <variant>_growing.png the pack's Medium healthy tree       (GROWING)
    <variant>_mature.png  the pack's Large healthy tree        (MATURE)
    <variant>_stump.png   the Large tree's stump               (what felling leaves)
    <variant>_top.png     the Large tree without its stump     (the part that falls)
    <variant>_cut_{left,right}_{1,2,3}.png   cut marks on the trunk, one more with each chop
    <variant>_sapling.png the soil and sapling                 (growth stage SAPLING)
    leaf_<variant>_N.png  falling leaves
    fx_chip_N.png, fx_poof_N.png, fx_dust_N.png    wood chips, the impact poof, dust
    trees.json            what each file is, its size, offset and the tree's pivot (`mml-trees-art/1`)
    ../icons/oak_sapling.png, pine_sapling.png     16 px inventory icons made from the saplings

Usage (also run by tools/import_game_assets.py):
    python3 tools/living_forest.py
"""
import gzip
import hashlib
import io
import json
import os
import re
import tarfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PACKAGE = "LivingForest_v1.3.2.unitypackage"
DEFAULT_DIR = "/home/user/My-Medieval-Life/private-assets"
ART = "Assets/LivingForest/Art/"
OUT = REPO / "game" / "assets" / "trees"
ICONS = REPO / "game" / "assets" / "icons"
FORMAT = "mml-trees-art/1"
REDUCE = 2                      # the art is 32 pixels per unit; the game's is 16
VARIANTS = {                    # id: (pack species folder, season folder)
    "oak_summer": ("Oak", "Summer"),
    "oak_autumn": ("Oak", "Autumn"),
    "oak_snow": ("Oak", "Snow"),
    "pine_summer": ("Pine", "Summer"),
    "pine_snow": ("Pine", "Snow"),
}
SIZES = {"young": "Small", "growing": "Medium", "mature": "Large"}       # the pack's size for each growth stage
CHIPS, POOFS, DUSTS, LEAVES = 4, 6, 2, 6
SAPLING_ICON = {"oak_sapling": "oak_summer", "pine_sapling": "pine_summer"}


def package_path():
    """The package file, or None. MML_PRIVATE_ASSETS names the folder that holds it."""
    folder = Path(os.environ.get("MML_PRIVATE_ASSETS") or DEFAULT_DIR)
    path = folder / PACKAGE
    return path if path.is_file() else None


class Package:
    """The assets of a .unitypackage by their Unity path (read once, in memory)."""

    def __init__(self, path):
        self.files = {}          # asset path -> bytes
        self.metas = {}          # asset path -> meta text
        guids = {}
        with tarfile.open(path, "r:gz") as tar:
            for member in tar:
                if not member.isfile():
                    continue
                guid, _, name = member.name.partition("/")
                if name in ("pathname", "asset", "asset.meta"):
                    guids.setdefault(guid, {})[name] = tar.extractfile(member).read()
        for entry in guids.values():
            if "pathname" in entry and "asset" in entry:
                p = entry["pathname"].decode("utf-8").splitlines()[0].strip()
                self.files[p] = entry["asset"]
                if "asset.meta" in entry:
                    self.metas[p] = entry["asset.meta"].decode("utf-8", "replace")

    def image(self, rel):
        from PIL import Image
        return Image.open(io.BytesIO(self.files[ART + rel])).convert("RGBA")

    def pivot(self, rel):
        """The sprite pivot from the meta file, as fractions (x from the left, y from the bottom)."""
        m = re.search(r"spritePivot: \{x: ([-0-9.e]+), y: ([-0-9.e]+)\}", self.metas[ART + rel])
        return float(m.group(1)), float(m.group(2))


def reduce_image(img, factor=REDUCE):
    """Half size by a box average of premultiplied colour, the alpha then cut at half: crisp edges."""
    import numpy as np
    from PIL import Image
    a = np.asarray(img).astype(np.float64)
    h, w = a.shape[0] // factor * factor, a.shape[1] // factor * factor
    a = a[:h, :w]
    alpha = a[..., 3:4] / 255.0
    pre = np.concatenate([a[..., :3] * alpha, a[..., 3:4]], axis=2)
    pre = pre.reshape(h // factor, factor, w // factor, factor, 4).mean(axis=(1, 3))
    cover = pre[..., 3:4] / 255.0
    rgb = np.where(cover > 0, pre[..., :3] / np.maximum(cover, 1e-6), 0)
    keep = cover >= 0.5
    out = np.concatenate([np.where(keep, rgb, 0), np.where(keep, 255.0, 0.0)], axis=2)
    return Image.fromarray(out.round().clip(0, 255).astype(np.uint8), "RGBA")


def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def import_trees(record, pkg_path):
    """Write game/assets/trees/* and the sapling icons from the package; record(dest, source, member,
    how) is the caller's provenance recorder. Returns the number of files written."""
    pkg = Package(pkg_path)
    OUT.mkdir(parents=True, exist_ok=True)
    written = []

    def save(img, dest, member, how, rel_dir=OUT):
        path = rel_dir / dest
        img.save(path)
        record(path, PACKAGE, ART + member, how)
        written.append(path)
        return img

    def crop(img):
        box = img.getbbox()
        return (img.crop(box), box) if box else (img, (0, 0, 0, 0))

    data = {"format": FORMAT,
            "note": ("Tree art from the Living Forest package, reduced to half size by tools/living_forest.py so it sits "
                     "beside the game's 16 px art; draw at scale 1, nearest filtering. Offsets and pivots are pixels in the "
                     "reduced canvas: `pivot` is the trunk base of a tree canvas, `off` the top-left of a cropped part in it."),
            "reduce": REDUCE, "variants": {}, "effects": {}}
    how_r = f"reduced to 1/{REDUCE} size (box average, alpha cut at half)"
    for vid, (sp, season) in VARIANTS.items():
        base = f"Trees/{sp}/{season}/"
        v = {"species": sp.lower(), "season": season.lower(), "sizes": {}}
        for stage, size in SIZES.items():
            rel = f"{base}{size}Healthy/T_tree.png"
            img = reduce_image(pkg.image(rel))
            px, py = pkg.pivot(rel)
            pivot = [round(px * img.width), round((1.0 - py) * img.height)]
            save(img, f"{vid}_{stage}.png", rel, how_r)
            v["sizes"][stage] = {"file": f"{vid}_{stage}.png", "w": img.width, "h": img.height, "pivot": pivot}
        big = f"{base}LargeHealthy/"
        pivot = v["sizes"]["mature"]["pivot"]
        v["pivot"] = pivot
        top = reduce_image(pkg.image(big + "T_top.png"))
        save(top, f"{vid}_top.png", big + "T_top.png", how_r)
        v["top"] = {"file": f"{vid}_top.png", "off": [0, 0], "w": top.width, "h": top.height}
        stump, box = crop(reduce_image(pkg.image(big + "T_stump.png")))
        save(stump, f"{vid}_stump.png", big + "T_stump.png", how_r + "; cropped to its pixels")
        v["stump"] = {"file": f"{vid}_stump.png", "off": [box[0], box[1]], "w": stump.width, "h": stump.height}
        v["cuts"] = {"left": [], "right": []}
        for side in ("left", "right"):
            for n in (1, 2, 3):
                cut, box = crop(reduce_image(pkg.image(f"{big}T_cut_{side}_{n}.png")))
                save(cut, f"{vid}_cut_{side}_{n}.png", f"{big}T_cut_{side}_{n}.png", how_r + "; cropped to its pixels")
                v["cuts"][side].append({"file": f"{vid}_cut_{side}_{n}.png", "off": [box[0], box[1]], "w": cut.width, "h": cut.height})
        sap_rel = f"{base}MediumHealthy/T_sapling.png"
        sap = reduce_image(pkg.image(sap_rel))
        sap, box = crop(sap)
        save(sap, f"{vid}_sapling.png", sap_rel, how_r + "; cropped to its pixels")
        # the sapling stands on the trunk base cell: its bottom centre is its pivot
        v["sapling"] = {"file": f"{vid}_sapling.png", "w": sap.width, "h": sap.height, "pivot": [sap.width // 2, sap.height]}
        v["leaves"] = []
        for n in range(LEAVES):
            leaf = pkg.image(f"{big}T_leaf_{n}.png")           # 2-4 px: kept at full size
            save(leaf, f"leaf_{vid}_{n}.png", f"{big}T_leaf_{n}.png", "copied unchanged (decoded and re-saved as PNG)")
            v["leaves"].append(f"leaf_{vid}_{n}.png")
        data["variants"][vid] = v
    fx = {"chips": ("Effects/T_chip_%d.png", CHIPS, "chip"), "poof": ("Effects/T_poof_%d.png", POOFS, "poof"),
          "dust": ("Effects/T_dust_%d.png", DUSTS, "dust")}
    for key, (pattern, count, stem) in fx.items():
        data["effects"][key] = []
        for n in range(count):
            img = pkg.image(pattern % n)
            if key == "poof":
                img = reduce_image(img)
                how = how_r
            else:
                how = "copied unchanged (decoded and re-saved as PNG)"
            save(img, f"fx_{stem}_{n}.png", pattern % n, how)
            data["effects"][key].append({"file": f"fx_{stem}_{n}.png", "w": img.width, "h": img.height})
    (OUT / "trees.json").write_text(json.dumps(data, indent=1, sort_keys=False) + "\n")
    # inventory icons: the sapling fitted into the 16 px icon cell (nearest, so the pixels stay crisp)
    from PIL import Image
    for item, vid in SAPLING_ICON.items():
        sp, season = VARIANTS[vid]
        rel = f"Trees/{sp}/{season}/MediumHealthy/T_sapling.png"
        img, _ = crop(pkg.image(rel))
        scale = min(16 / img.width, 16 / img.height)
        icon = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.BOX)
        cell = Image.new("RGBA", (16, 16))
        cell.alpha_composite(icon, ((16 - icon.width) // 2, 16 - icon.height))
        path = ICONS / f"{item}.png"
        cell.save(path)
        record(path, PACKAGE, ART + rel, "cropped to its pixels and fitted into a 16 px icon (box filter, bottom centre)")
        written.append(path)
    return len(written) + 1


def import_into(prov, record):
    """The one entry point: import the trees if the package is there (replacing their provenance
    entries in `prov`, a list the caller keeps), else say so and carry the existing entries over."""
    path = package_path()
    if path is None:
        print(f"{PACKAGE} not found (MML_PRIVATE_ASSETS or {DEFAULT_DIR}): tree import skipped; "
              "game/assets/trees is left as it is")
        old = REPO / "game" / "assets" / "PROVENANCE.json"
        if old.exists():
            prov.extend(e for e in json.loads(old.read_text())["files"] if e.get("source") == PACKAGE)
        return 0
    n = import_trees(record, path)
    record(OUT / "trees.json", PACKAGE, "(generated)",
           "tools/living_forest.py: what each imported tree file is, its size, offset and pivot")
    print(f"imported {n} tree files into game/assets/trees from {path.name}")
    return n


def main():
    """Only the tree step, keeping every other provenance entry as it is."""
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
