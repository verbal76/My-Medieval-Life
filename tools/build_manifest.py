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
    "PunyMonsters.zip": ("CC0", "Puny Monsters: 9 animals/monsters (panther, dog, 2 boars, 2 spiders, wolf, rat, cat), each 384x256 = 12 frames x 8 directions, 32px cells. Second download on the free Puny Characters itch.io page, under its CC0 licence."),
    "PUNY_WORLD_v1.zip": ("verify", "FREE Puny World overworld tileset (432x1040, 1755 tiles) with 5 sample Tiled maps. Its .tsx has a full Tiled terrain setup: corner wangset 'overworld' (grass, dirt, sand, cliff, river, 3 sea depths; trees/trees2/cliff-transparent as an overlay over 'air') and edge wangset 'pathways' (dirt, sand, water paths). Basis for tools/puny_world_terrain.py. Linked as 'Free 16x16 Puny World Tileset' from Shade's pages; licence page not yet seen."),
    "PUNY_DUNGEON_v1.zip": ("CC0", "Puny Dungeon tileset (416x320): 2-edge wang walls laid out for procedural maps, floor variations, animated water and torches, traps (boulder, spikes, blades, flamethrowers, pits, bear traps), interactables (pressure plates, crates, portals, keys). 5 sample Tiled maps with preview images, sample characters. Note: the .tsx defines animations but no wangset, so the wall layout must be mapped by hand before auto-tiling."),
    "MiniWorldSprites.zip": ("free", "16x16 Miniworld: buildings in 5 team colours, units, monsters, animals, nature, ground, UI. Shade's guide: free to use, no credit needed, do not resell."),
    "CozyFarm_full_version.zip": ("paid", "Cozy Farm (full version) by shubibubi, 16x16 grid, the same scale as the Puny packs. Uploaded as full_version.zip and stored under this name, bytes unchanged. Animals with walk/sleep sheets (cows in 3 colours, pigs, sheep, goats, chickens, turkey, bunnies, plus babies; frame sizes in info.txt), 37 crops with growth stages (also wet and winter variants), seeds, scarecrows, farm tools, artisan machines (butter churn, cheese press, spindle, cloth and mayo makers), seasonal trees, flowers and gates, farm tiles, buildings (barn, coop, market, greenhouse, NPC houses, plus a hospital, museum and slime hut that fit the setting less), slime and bat enemies, UI and item icons. No licence file in the archive. Bought by the owner on itch.io (shubibubi.itch.io, Cozy Farm Asset Pack, full version dated 2021-12-06; purchase page screenshot 2026-10-17). Complete-version licence per the pack page (owner screenshot 2026-10-17): usable in any commercial or non-commercial project, modification allowed, no resale or redistribution even if modified, credit appreciated."),
    "kenney_input-prompts_1.5.zip": ("CC0", "Input Prompts 1.5 by Kenney (kenney.nl): over 1,500 button and key icons for Xbox, PlayStation, Nintendo, Steam devices, keyboard and mouse, touch gestures and generic controls, as 64 px and 128 px PNGs, SVGs, sprite sheets and fonts. CC0 per the archive's License.txt and the itch.io page (owner screenshot 2026-10-18). Used for the control prompts on screen."),
    "Simple_Falt_Game_Interface_Pack.zip": ("paid", "Simple Flat Game Interface Kit by SunGraphica (sungraphica.itch.io; the archive is spelt \"Falt\"), bought by the owner on itch.io in SunGraphica's All-in-One Game UI bundle on 2026-03-12 (purchase page screenshot 2026-10-18). Menu, inventory, items, levels, settings, shop, level-complete and progress-bar screens as PSDs and as PNG pieces in five colours (PNG, Blue, Green, Pink, Red), two icon sets and a 512 px button. The archive's only note names the author and store; the bundle also offers a \"FREE ver.zip\", not uploaded. No licence file. Not used in the game yet."),
    "SunGraphica_Minimal_Icons_FREE.zip": ("paid", "The free version of \"600 clean and minimal game Icons ultimate pack\" by SunGraphica, uploaded as FREE.zip and stored under this name, bytes unchanged. Part of the same All-in-One Game UI bundle the owner bought on itch.io on 2026-03-12 (purchase page screenshot 2026-10-18). About 90 minimal game icons in light and dark versions at 0.5x, 1x and 2x. The full pack (\"Minimal icons.zip\", 73 MB) is not uploaded. No licence file. Not used in the game yet."),
    "kenney_splatpack.zip": ("CC0", "Splat Pack 1.0 by Kenney (kenney.nl): 36 white splat shapes as 256 px and 512 px PNGs and SVGs. CC0 per the archive's License.txt (credit appreciated, not required). Used, shrunk and tinted, for blood where someone is slain; meant later for thrown potions and water splashes."),
    "My_Medieval_Life_Icon_Pack.zip": ("verify", "The game's app icon, supplied by the owner on 2026-10-18: one picture (a ragged hero with a rusty sword before a village and castle, in a gold rounded frame) at 48, 72, 96, 144, 192, 256, 432, 512 and 1024 px. No licence file in the archive; origin and terms to be confirmed by the owner."),
    "TinyRanch_Assets.zip": ("free", "Tiny Ranch by Gustavo Vituri, drawn on an 8x8 grid (half the 16x16 scale of the Puny packs): farm animals with walk frames (cows, pigs, sheep, chickens, ducks, geese, horses and more), 8 crops with seed, growth stages and harvest icons, farm items, trees and rocks, barns, silos, windmill and well, tilled soil and grass tiles, and 8x8 farmer characters. No licence file in the archive; per the itch.io page (screenshot from the owner): free for personal and commercial use, modification allowed, crediting not required but appreciated (credit Gustavo Vituri), do not redistribute, no NFTs."),
    "16x16 miniworld - octoshrimpy  -  indoor update.zip": ("CC BY 4.0", "16x16 miniworld + by octoshrimpy (remix/extension of Shade's Miniworld), the 'legacy - indoor update' download (older version): characters, buildings, nature, walls, indoor things, terrain + terrain decor sheets."),
    "miniworld +__rainbow-refresh.zip": ("CC BY 4.0", "16x16 miniworld + by octoshrimpy, rainbow refresh (02/15/2023, newer): recoloured sheets plus chests. terrain.png has 20 terrain modules (water depths, sand, grasses, forest, snow, ice, dirts, cave floors) in one shared autotile layout; no Tiled/wang data included."),
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
    "private-assets/LivingForest_v1.3.2.unitypackage": "Paid; kept out of the public repository (private asset workflow), its game files imported by tools/import_game_assets.py. Living Forest, Tree Lifecycle & Chopping System v1.3.2 by YET ART STUDIO, a Unity package (gzip tar) supplied by the owner on 2026-10-18, bytes unchanged: 1,086 assets (874 PNG: oak and pine trees in summer, autumn and snow at 3 sizes and 3 health stages, stumps, chopped tops, saplings, rot and collapse frames, chips, dust, leaves, birds, log and plank items, night mushrooms and fireflies, Halloween props; 20 WAV sound effects; Unity prefabs, C# and shaders). Pack licence (LICENSE.txt): the purchaser may use, modify and ship the assets packed in their own games; credit appreciated, \"Trees by YET ART STUDIO\". Some sounds are built from CC0 sources (Kenney Impact Sounds; farfadet46; EZduzziteh, per CREDITS.txt). Not yet imported into the game.",
    "Miniworld-Guide.docx": "Shade's guide to Miniworld buildings and animation timings.",
    "punyworld-dungeon-tileset.png": "Loose copy of the Puny Dungeon tileset (identical to the one inside PUNY_DUNGEON_v1.zip); CC0.",
}
# Asset folders committed unzipped: name -> (licence, description)
FOLDER_NOTES = {
    "Flat Game UI Icon Pack": ("verify", "Flat game UI pack supplied by the owner on 2026-10-18 in parts (the owner's folder is \"Flat design UI pack\"): icon sets 1 and 2 (white glyphs on dark rounded squares: interface, media and platform icons; RPG items, weapons, armour, potions, scrolls and status icons) as Illustrator .ai and .eps; \"Flat game UI set 3\" (login, skills, pause, levels, win, shop, upgrade and settings windows in several colour schemes) as .ai and .pdf; and preview images (exact duplicate uploads dropped). Set 3's .eps and .svg could not be uploaded; the .ai and .pdf hold the same art. No licence file; source and terms to be confirmed by the owner."),
    "16x16 Assorted RPG Icons (partial)": ("free", "Sheets from Shade's free 16x16 Assorted RPG Icons pack, shared individually (not the full pack): books, chests, consumables, potions, weapons, armours, tools/gems/ingots, misc items."),
}
NOT_ASSETS = {"private-assets", "ASSET_MANIFEST.md", "asset_manifest.csv", ".gitignore", "tools", "out", ".git",
              "data", "docs", "tests", "research", "game", ".github", "CLAUDE.md", "README.md"}


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
           "**CC0** = public domain per the itch.io page. **CC BY 4.0** = free to use but credit is required: the miniworld+ page text says CC0 but its official asset-license field says CC BY 4.0, so credit octoshrimpy. **verify** = no licence file in the archive; check the itch.io page.", ""]

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
