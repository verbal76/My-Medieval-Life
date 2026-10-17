"""Building atlas for the Miniworld building sheets, keyed by the guide's names.

Shade's Miniworld-Guide.docx shows each named building as a small picture
(usually a row of 2-3 variants). This tool finds every one of those pictures
in MiniWorldSprites.zip by exact pixel matching, splits the match into the
individual building sprites it contains, and finds the same sprite in each
team-colour sheet. Every other sprite on the building sheets is listed as
unidentified instead of being given a guessed name.

Writes data/miniworld_buildings.json. With --previews, also writes a
labelled contact sheet to out/miniworld_buildings/.

Usage:
    python3 tools/miniworld_buildings.py [--previews]
"""
import argparse
import io
import json
import re
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from assetzip import REPO

ZIP = "MiniWorldSprites.zip"
GUIDE = "Miniworld-Guide.docx"
ROOT = "MiniWorldSprites/Buildings/"
OUT_JSON = REPO / "data" / "miniworld_buildings.json"
TEAMS = ["Red", "Cyan", "Lime", "Purple"]
T = 16


def guide_entries():
    """[(category, name, PNG bytes)] in the guide's table order."""
    z = zipfile.ZipFile(REPO / GUIDE)
    doc = z.read("word/document.xml").decode()
    rels = z.read("word/_rels/document.xml.rels").decode()
    target = {}
    for rel in re.findall(r"<Relationship [^>]*>", rels):
        rid = re.search(r'Id="(rId\d+)"', rel)
        tgt = re.search(r'Target="(media/[^"]+)"', rel)
        if rid and tgt:
            target[rid.group(1)] = tgt.group(1)
    entries, category = [], None
    for row in re.findall(r"<w:tr[ >].*?</w:tr>", doc, flags=re.S):
        cells = re.findall(r"<w:tc>.*?</w:tc>", row, flags=re.S)
        texts = ["".join(re.findall(r"<w:t[^>]*>([^<]*)</w:t>", c)).strip() for c in cells]
        imgs = re.findall(r'r:embed="(rId\d+)"', row)
        if imgs and len(texts) > 1:
            name = re.sub(r"\s*\(but not Obama\)", "", texts[1])
            entries.append((category, name, z.read("word/" + target[imgs[0]])))
        elif texts and texts[0] and texts[0] not in ("IMAGE",):
            category = texts[0].title()
    return entries


def rgba(data):
    return np.array(Image.open(io.BytesIO(data)).convert("RGBA")).astype(np.int16)


def load_sheets():
    z = zipfile.ZipFile(REPO / ZIP)
    return {n[len(ROOT):]: rgba(z.read(n)) for n in sorted(z.namelist())
            if n.startswith(ROOT) and n.endswith(".png")}


def match(pic, sheets, names):
    """Best placement of pic in any of the named sheets, allowing it to hang 2px
    off the sheet edge (some guide crops are a pixel too big). Score = matching
    opaque pixels / pixels opaque in either image."""
    ph, pw = pic.shape[:2]
    pa = pic[..., 3] > 0
    best = (0.0, None)
    for name in names:
        s = sheets[name]
        pad = np.zeros((s.shape[0] + 4, s.shape[1] + 4, 4), np.int16)
        pad[2:-2, 2:-2] = s
        for oy in range(pad.shape[0] - ph + 1):
            for ox in range(pad.shape[1] - pw + 1):
                win = pad[oy:oy + ph, ox:ox + pw]
                wa = win[..., 3] > 0
                tot = (pa | wa).sum()
                if not tot:
                    continue
                good = (pa & wa & (win[..., :3] == pic[..., :3]).all(-1)).sum()
                if good / tot > best[0]:
                    best = (good / tot, (name, ox - 2, oy - 2))
    return best


def opaque(sheet, x, y, w=T, h=T):
    return sheet[y:y + h, x:x + w, 3] > 0


def continues(a, b, horizontal_edge=False):
    """True when artwork runs on across a tile edge. a, b: the two pixel strips
    on either side. Side-by-side neighbours also touch, but there every touching
    pixel pair is the dark outline of both sprites. Stacked neighbours touch
    where one building's grass/shadow base meets the next one's outline, so a
    horizontal edge only counts as continuous where interior colours meet."""
    both = (a[:, 3] > 0) & (b[:, 3] > 0)
    if not both.any():
        return False
    da, db = a[:, :3].max(1) < 70, b[:, :3].max(1) < 70
    if horizontal_edge:
        inner = (both & ~da & ~db).sum()
        return inner >= 3 and inner / both.sum() >= 0.3
    return (both & da & db).sum() / both.sum() < 0.9


def group_tiles(sheet, tiles):
    """Merge grid tiles whose artwork continues across a shared edge into sprites."""
    tiles = sorted(set(tiles))
    parent = {t: t for t in tiles}

    def find(t):
        while parent[t] != t:
            t = parent[t]
        return t

    for (x, y) in tiles:
        for nx, ny in ((x + T, y), (x, y + T)):
            if (nx, ny) not in parent:
                continue
            if nx != x:
                touch = continues(sheet[y:y + T, x + T - 1], sheet[ny:ny + T, nx])
            else:
                touch = continues(sheet[y + T - 1, x:x + T], sheet[ny, nx:nx + T], horizontal_edge=True)
            if touch:
                parent[find((nx, ny))] = find((x, y))
    groups = {}
    for t in tiles:
        groups.setdefault(find(t), []).append(t)
    rects = []
    for g in groups.values():
        xs = [x for x, _ in g]
        ys = [y for _, y in g]
        rects.append([min(xs), min(ys), max(xs) + T - min(xs), max(ys) + T - min(ys)])
    return sorted(rects, key=lambda r: (r[1], r[0]))


def tiles_in(sheet, x, y, w, h):
    """Non-empty grid tiles covered by a pixel area (snapped to the 16px grid)."""
    out = []
    for ty in range(max(0, y // T * T), min(sheet.shape[0], y + h), T):
        for tx in range(max(0, x // T * T), min(sheet.shape[1], x + w), T):
            ox0, oy0 = max(tx, x), max(ty, y)
            ox1, oy1 = min(tx + T, x + w), min(ty + T, y + h)
            if ox1 > ox0 and oy1 > oy0 and opaque(sheet, ox0, oy0, ox1 - ox0, oy1 - oy0).sum() > 8:
                out.append((tx, ty))
    return out


def base_name(file):
    """'Red/RedMarket.png' and 'Wood/Market.png' -> 'Market.png'."""
    folder, name = file.split("/", 1)
    return name[len(folder):] if folder in TEAMS and name.startswith(folder) else name


def team_versions(sheets, file, rect):
    """Same building in the wood and team-colour sheets: same place, same silhouette."""
    base = base_name(file)
    x, y, w, h = rect
    src = opaque(sheets[file], x, y, w, h)
    found = {}
    for team, other in [("wood", f"Wood/{base}")] + [(t.lower(), f"{t}/{t}{base}") for t in TEAMS]:
        if other == file or other not in sheets or sheets[other].shape != sheets[file].shape:
            continue
        mine = opaque(sheets[other], x, y, w, h)
        iou = (src & mine).sum() / max(1, (src | mine).sum())
        if iou >= 0.85:
            found[team] = {"file": ROOT + other, "rect": rect, "silhouette_iou": round(float(iou), 3)}
    return found


def build():
    sheets = load_sheets()
    sprite_sheets = [n for n in sheets if "Preview" not in n]
    wood_first = [n for n in sprite_sheets if n.startswith(("Wood/", "Enemy/"))]
    buildings, claimed = [], {}
    for category, name, png in guide_entries():
        pic = rgba(png)
        entry = {"name": name, "category": category, "guide_size": [pic.shape[1], pic.shape[0]],
                 "variants": [], "uncertain": None}
        score, where = match(pic, sheets, wood_first)
        placements = []
        if score == 1.0:
            placements.append((where[0], where[1], where[2], pic.shape[1], pic.shape[0], 1.0))
        else:
            # the picture is assembled from tiles in different places: match tile by tile
            for tx in range(0, pic.shape[1] - T + 1, T):
                s, w = match(pic[:T, tx:tx + T], sheets, wood_first)
                if s < 1.0:
                    s2, w2 = match(pic[:T, tx:tx + T], sheets, sprite_sheets)
                    if s2 > s:
                        s, w = s2, w2
                placements.append((w[0], w[1], w[2], T, T, s))
        for file, x, y, w, h, s in placements:
            for rect in group_tiles(sheets[file], tiles_in(sheets[file], x, y, w, h)):
                key = (file, tuple(rect))
                if key in claimed:
                    continue
                claimed[key] = name
                teams = team_versions(sheets, file, rect)
                src = ROOT + file
                if "wood" in teams:
                    # keep wood as the primary sheet, like every other building
                    folder = file.split("/", 1)[0].lower()
                    teams[folder] = {"file": src, "rect": rect, "silhouette_iou": 1.0}
                    src = teams.pop("wood")["file"]
                v = {"file": src, "rect": rect, "match": round(float(s), 3),
                     "matched_in": ROOT + file, "teams": dict(sorted(teams.items()))}
                entry["variants"].append(v)
        worst = min(v["match"] for v in entry["variants"])
        if worst < 1.0:
            entry["uncertain"] = (f"guide picture only partly matches the sheets (best {worst:.0%}); "
                                  "the listed sprite is the closest candidate, the guide may show an "
                                  "older drawing")
        buildings.append(entry)

    # every other sprite on the building sheets, so nothing is silently skipped
    covered = {(ROOT + f, r) for (f, r) in claimed}
    for b in buildings:
        for v in b["variants"]:
            covered.add((v["file"], tuple(v["rect"])))
            for t in v["teams"].values():
                covered.add((t["file"], tuple(t["rect"])))
    # one entry per sprite position, with all colour versions of it
    unidentified = {}
    for file in sprite_sheets:
        s = sheets[file]
        taken = {(tx, ty) for (f, (x, y, w, h)) in covered if f == ROOT + file
                 for tx in range(x, x + w, T) for ty in range(y, y + h, T)}
        tiles = [(x, y) for y in range(0, s.shape[0], T) for x in range(0, s.shape[1], T)
                 if opaque(s, x, y).sum() > 8 and (x, y) not in taken]
        for rect in group_tiles(s, tiles):
            key = (base_name(file), tuple(rect))
            u = unidentified.setdefault(key, {"sheet_hint": Path(base_name(file)).stem,
                                              "rect": rect, "files": []})
            u["files"].append(ROOT + file)
    unidentified = sorted(unidentified.values(), key=lambda u: (u["sheet_hint"], u["rect"][1], u["rect"][0]))
    previews = [ROOT + n for n in sheets if "Preview" in n]
    return {
        "format": "miniworld-buildings/1",
        "source": ZIP,
        "guide": GUIDE,
        "about": ("rect = [x, y, w, h] in the sheet. 'teams' gives the same building in the "
                  "red/cyan/lime/purple sheets where one exists. 'match' 1.0 = pixel-identical to the "
                  "guide picture."),
        "buildings": buildings,
        "unidentified": unidentified,
        "not_sprite_sheets": previews,
    }


def contact_sheet(meta, out):
    z = zipfile.ZipFile(REPO / ZIP)
    cache = {}

    def crop(file, rect):
        if file not in cache:
            cache[file] = Image.open(io.BytesIO(z.read(file))).convert("RGBA")
        x, y, w, h = rect
        return cache[file].crop((x, y, x + w, y + h))

    rows = []
    for b in meta["buildings"]:
        for i, v in enumerate(b["variants"]):
            imgs = [("wood" if "/Wood/" in v["file"] else Path(v["file"]).parent.name.lower(),
                     crop(v["file"], v["rect"]))]
            imgs += [(t, crop(tv["file"], tv["rect"])) for t, tv in v["teams"].items()]
            flag = "" if v["match"] == 1.0 else f"  UNCERTAIN match {v['match']:.0%}"
            rows.append((f"{b['name']} #{i + 1}  {Path(v['file']).name} {v['rect']}{flag}", imgs,
                         v["match"] < 1.0))
    s = 3
    cell = 32 * s + 8
    width = 330 + 5 * cell
    img = Image.new("RGBA", (width, len(rows) * cell + 10), (28, 30, 28, 255))
    d = ImageDraw.Draw(img)
    for r, (label, imgs, unsure) in enumerate(rows):
        y = r * cell + 5
        d.text((6, y + cell // 2 - 6), label[:52], fill=(255, 120, 120) if unsure else (235, 235, 160))
        for k, (team, im) in enumerate(imgs):
            bg = Image.new("RGBA", im.size, (88, 120, 80, 255))
            bg.alpha_composite(im)
            big = bg.resize((im.width * s // max(1, im.width // 32 + (im.width % 32 > 0)) if im.width > 32 else im.width * s,
                             im.height * s // max(1, im.height // 32 + (im.height % 32 > 0)) if im.height > 32 else im.height * s),
                            Image.NEAREST)
            img.paste(big, (330 + k * cell, y))
            d.text((330 + k * cell, y + big.height), team, fill=(200, 200, 200))
    img.save(out / "buildings_contact_sheet.png")

    # unidentified sprites, grouped by sheet hint
    un = meta["unidentified"]
    cols = 10
    img = Image.new("RGBA", (cols * (32 * s + 10), (len(un) // cols + 1) * (32 * s + 24)), (28, 30, 28, 255))
    d = ImageDraw.Draw(img)
    for i, u in enumerate(un):
        im = crop(u["files"][0], u["rect"])
        f = min(s, (32 * s) // max(im.width, im.height))
        bg = Image.new("RGBA", im.size, (88, 120, 80, 255))
        bg.alpha_composite(im)
        x, y = (i % cols) * (32 * s + 10), (i // cols) * (32 * s + 24)
        img.paste(bg.resize((im.width * f, im.height * f), Image.NEAREST), (x, y))
        d.text((x, y + 32 * s + 2), f"{u['sheet_hint']} {u['rect'][0]},{u['rect'][1]} x{len(u['files'])}",
               fill=(200, 200, 200))
    img.save(out / "unidentified_sprites.png")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--previews", action="store_true")
    ap.add_argument("-o", "--out", default="out/miniworld_buildings")
    args = ap.parse_args()
    meta = build()
    OUT_JSON.parent.mkdir(exist_ok=True)
    OUT_JSON.write_text(json.dumps(meta, indent=1) + "\n")
    n_var = sum(len(b["variants"]) for b in meta["buildings"])
    unsure = [b["name"] for b in meta["buildings"] if b["uncertain"]]
    print(f"wrote {OUT_JSON.relative_to(REPO)}: {len(meta['buildings'])} buildings, {n_var} sprites, "
          f"{len(meta['unidentified'])} unidentified sprites; uncertain: {unsure or 'none'}")
    if args.previews:
        out = Path(args.out)
        out.mkdir(parents=True, exist_ok=True)
        contact_sheet(meta, out)
        print("previews written to", out)


if __name__ == "__main__":
    main()
