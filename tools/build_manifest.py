"""Build ASSET_MANIFEST.md and asset_manifest.csv from every archive in the repo.

The CSV lists every file inside every zip (size, sha256, image size/frames).
The Markdown summarises each archive by folder and flags content that is
byte-identical across or within archives.

Usage:
    python3 tools/build_manifest.py
"""
import csv
import hashlib
import io
import zipfile
from collections import Counter, defaultdict
from pathlib import Path, PurePosixPath

from PIL import Image

from assetzip import REPO

# What each upload is, from its contents and the itch.io receipt.
# "paid" = in the 50% Sale October bundle receipt; its licence forbids
# redistributing the original files.
NOTES = {
    "16x16 Armour RPG Icons.zip": ("paid", "Armour icon sheets: boots, breastplates, headgear, trousers."),
    "16x16 Jewelry RPG Icons.zip": ("paid", "Jewelry icons (rings, necklaces, bracelets, brooches...) as sheets plus thousands of individual 16x16 PNGs. Includes LICENSE.txt."),
    "16x16 Survival RPG Icons.zip": ("paid", "Survival/crafting icons by category (food, gems, plants & alchemy, textile, armour, dirt & clay...). Includes LICENSE.txt."),
    "PUNY-WORLD-PAID_v1.zip": ("paid", "Puny World medieval tileset: 3520x2112 tile sheet, atlas, 9 sample Tiled maps, sample 32x32 characters, GIF previews."),
    "PUNY_CHARACTERS_v2.1.zip": ("paid", "Puny Characters Editor Edition: pre-made 8-direction spritesheets, GIMP layer file, Tiled ortho/iso/hex demo maps (ortho tileset has a terrain wangset)."),
    "PUNY_CHARACTERS_v2.1_tdsm-2026.zip": ("paid", "Puny Characters as a Top-Down Sprite Maker style: manifest.tds, per-layer part sheets, CSV part lists, palette ramps. This is the headless character generator's source (tools/puny_chargen.py)."),
    "PUNY_SKILLS_v1.zip": ("paid", "Puny skill icons, skill FX animation spritesheets, indicators."),
    "PUNY_MYTH-CREATURES-RPGMAKER_v1.zip": ("CC0", "Puny Myth Creatures (Philippine folklore), RPG Maker format: 30 overworld 4-direction walk sheets (72x96, 3x4 frames of 24px), 25 unanimated enemy battle sprites, 10 hero side-view battlers (576x384, 9x6 frames of 64px), and 9 RPG Maker character sheets (288x192). Shade's thesis pack; CC0, credit optional."),
    "Puny-Characters.zip": ("CC0", "Free Puny Characters: 19 8-direction sheets (768x256 = 24 frames x 8 directions, 32px cells; idle, walk, sword, bow, stave, throw, hurt, death): Character-Base plus soldiers, warriors, archers, mages, workers and orcs in team colours; a 480x32 single-row Slime sheet; 4 environment tiles (16x16). Older/smaller layout than the 29-frame Editor Edition."),
    "PunyMonsters.zip": ("verify", "Puny Monsters: 9 animals/monsters (panther, dog, 2 boars, 2 spiders, wolf, rat, cat), each 384x256 = 12 frames x 8 directions, 32px cells. No licence shown with the upload."),
    "PUNY_DUNGEON_v1.zip": ("verify", "Puny Dungeon tileset (416x320), 5 sample Tiled maps with preview images, sample characters."),
    "MiniWorldSprites.zip": ("free", "16x16 Miniworld: buildings in 5 team colours, units, monsters, animals, nature, ground, UI. Shade's guide: free to use, no credit needed, do not resell."),
    "16x16 miniworld - octoshrimpy  -  indoor update.zip": ("verify", "Miniworld remix sheets by octoshrimpy (a different artist), adding indoor tiles and walls."),
    "miniworld +__rainbow-refresh.zip": ("verify", "Recoloured 'rainbow refresh' Miniworld remix sheets, same layout as the octoshrimpy update plus chests."),
    "Character-Customizer.zip": ("verify", "Manual character customiser: GIMP .xcf and Photoshop layer files plus ReadMe. Not scriptable as-is."),
    "ClimbUp_restore_backup.zip": ("n/a", "NOT an art pack: backup of a separate 'Climb up' game-designer project (project.json + splash image)."),
}


def image_info(data):
    try:
        im = Image.open(io.BytesIO(data))
        return im.size, getattr(im, "n_frames", 1), im.mode
    except Exception:
        return None, None, None


def human(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TB"


LOOSE_NOTES = {
    "Miniworld-Guide.docx": "Shade's guide to Miniworld buildings and animation timings.",
    "punyworld-dungeon-tileset.png": "Loose copy of the Puny Dungeon tileset (identical to the one inside PUNY_DUNGEON_v1.zip).",
}
# Asset folders committed unzipped: name -> (licence, description)
FOLDER_NOTES = {
    "16x16 Assorted RPG Icons (partial)": ("free", "Sheets from Shade's free 16x16 Assorted RPG Icons pack, shared individually (not the full pack): books, chests, consumables, potions, weapons, armours, tools/gems/ingots, misc items."),
}
NOT_ASSETS = {"ASSET_MANIFEST.md", "asset_manifest.csv", ".gitignore", "tools", "out", ".git"}


def main():
    rows = []
    loose = []
    folders = []
    for p in sorted(REPO.iterdir()):
        if p.name in NOT_ASSETS or p.suffix == ".zip" or p.name.startswith("."):
            continue
        files = [p] if p.is_file() else sorted(f for f in p.rglob("*") if f.is_file())
        if p.is_file():
            loose.append(p.name)
        else:
            folders.append(p.name)
        for f in files:
            data = f.read_bytes()
            size, frames, mode = image_info(data) if f.suffix in (".png", ".gif") else (None, None, None)
            rows.append({"archive": "(repo root)" if p.is_file() else p.name + "/",
                         "path": f.relative_to(REPO if p.is_file() else p).as_posix(),
                         "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
                         "width": size[0] if size else "", "height": size[1] if size else "",
                         "frames": frames or "", "mode": mode or ""})
    zips = sorted(REPO.glob("*.zip"))
    for zp in zips:
        z = zipfile.ZipFile(zp)
        for info in z.infolist():
            if info.is_dir():
                continue
            data = z.read(info)
            size, frames, mode = (None, None, None)
            if info.filename.lower().endswith((".png", ".gif")):
                size, frames, mode = image_info(data)
            rows.append({"archive": zp.name, "path": info.filename, "bytes": len(data),
                         "sha256": hashlib.sha256(data).hexdigest(),
                         "width": size[0] if size else "", "height": size[1] if size else "",
                         "frames": frames or "", "mode": mode or ""})

    with open(REPO / "asset_manifest.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)

    by_hash = defaultdict(list)
    for r in rows:
        by_hash[r["sha256"]].append(r)
    dupes = {h: rs for h, rs in by_hash.items() if len(rs) > 1}

    md = ["# Asset manifest", "",
          "Generated by `tools/build_manifest.py`. Every file inside every archive, with its",
          "size, SHA-256 and image dimensions, is in [`asset_manifest.csv`](asset_manifest.csv).",
          "", "## Archives", "",
          "| Archive | Licence | Files | Unpacked | What it is |",
          "|---|---|---:|---:|---|"]
    by_arch = defaultdict(list)
    for r in rows:
        by_arch[r["archive"]].append(r)
    for zp in zips:
        lic, desc = NOTES.get(zp.name, ("verify", ""))
        rs = by_arch[zp.name]
        md.append(f"| `{zp.name}` | {lic} | {len(rs)} | {human(sum(r['bytes'] for r in rs))} | {desc} |")
    for name in folders:
        lic, desc = FOLDER_NOTES.get(name, ("verify", ""))
        rs = by_arch[name + "/"]
        md.append(f"| `{name}/` (folder) | {lic} | {len(rs)} | {human(sum(r['bytes'] for r in rs))} | {desc} |")
    for name in loose:
        md.append(f"| `{name}` (loose file) | | 1 | {human((REPO / name).stat().st_size)} | "
                  f"{LOOSE_NOTES.get(name, '')} |")
    md += ["", "Licence key: **paid** = bought in the itch.io bundle; its licence allows use in games",
           "but forbids redistributing the original files. **free** = Shade's own terms say free to use.",
           "**CC0** = public domain per Shade's itch.io page. **verify** = no licence file in the archive; check the itch.io page.", ""]

    exts = Counter(PurePosixPath(r["path"]).suffix.lower() or "(none)" for r in rows)
    md += ["## File types", "", "| Extension | Count |", "|---|---:|"]
    md += [f"| `{e}` | {c} |" for e, c in exts.most_common()]
    md.append("")

    md += ["## Contents by folder", "",
           "Each folder lists its file count and the most common image sizes.", ""]
    for source in [zp.name for zp in zips] + [f + "/" for f in folders]:
        md += [f"### {source}", ""]
        subdirs = defaultdict(list)
        for r in by_arch[source]:
            subdirs[str(PurePosixPath(r["path"]).parent)].append(r)
        md += ["| Folder | Files | Image sizes | Examples |", "|---|---:|---|---|"]
        for folder in sorted(subdirs):
            rs = subdirs[folder]
            dims = Counter(f"{r['width']}x{r['height']}" for r in rs if r["width"])
            dim_s = ", ".join(f"{d} ({c})" if len(dims) > 1 else d for d, c in dims.most_common(3))
            if len(dims) > 3:
                dim_s += ", ..."
            ex = ", ".join(f"`{PurePosixPath(r['path']).name}`" for r in rs[:4])
            if len(rs) > 4:
                ex += ", ..."
            md.append(f"| `{folder}` | {len(rs)} | {dim_s} | {ex} |")
        md.append("")

    md += ["## Identical content", "",
           f"{len(dupes)} distinct files appear more than once (byte-identical, by SHA-256).",
           "These are copies inside the packs, not duplicate uploads, so nothing was removed.", ""]
    pairs = Counter()
    for rs in dupes.values():
        archs = tuple(sorted({r["archive"] for r in rs}))
        pairs[archs] += 1
    md += ["| Where the copies are | Distinct files |", "|---|---:|"]
    md += [f"| {' + '.join(f'`{a}`' for a in k)} | {c} |" for k, c in pairs.most_common()]
    md.append("")

    (REPO / "ASSET_MANIFEST.md").write_text("\n".join(md))
    print(f"{len(rows)} files, {len(dupes)} duplicated contents")


if __name__ == "__main__":
    main()
