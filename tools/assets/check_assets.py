"""Validate the game's imported assets (asset-integration-pipeline skill).

Errors (exit 1):
  - a PROVENANCE.json entry whose file is missing or whose sha256 differs (an untracked edit);
  - a file in game/assets (other than Godot's .import/.uid files) that PROVENANCE.json does not list
    (art that did not come through tools/import_game_assets.py);
  - a literal "res://..." path in game scripts, scenes or data that does not exist;
  - an animation row table (AnimalSprite.ROWS) naming a row or frame the sheet does not have.
Report only (never an error): imported files nothing in the game names, so possibly unused.

    python3 tools/assets/check_assets.py [--unused]
"""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sheets  # noqa: E402

REPO = sheets.REPO
GAME = REPO / "game"
ASSETS = GAME / "assets"
RES_RE = re.compile(r'"(res://[^"%{}]+?\.(?:png|tres|tscn|gd|json|wav|ogg|ttf|svg))"')
SKIP_SUFFIX = (".import", ".uid")


def provenance():
    p = json.loads((ASSETS / "PROVENANCE.json").read_text())
    return p.get("files", p) if isinstance(p, dict) else p


def check_provenance(errors):
    listed = set()
    for f in provenance():
        path = GAME / f["file"]
        listed.add(str(path.relative_to(GAME)))
        if not path.exists():
            errors.append("PROVENANCE lists a missing file: %s" % f["file"])
        elif f.get("sha256") and hashlib.sha256(path.read_bytes()).hexdigest() != f["sha256"]:
            errors.append("%s differs from its recorded import (sha256): re-run tools/import_game_assets.py" % f["file"])
    for path in sorted(ASSETS.rglob("*")):
        if path.is_file() and not path.name.endswith(SKIP_SUFFIX) and path.name != "PROVENANCE.json":
            rel = str(path.relative_to(GAME))
            if rel not in listed:
                errors.append("%s is not in PROVENANCE.json (import art only through tools/import_game_assets.py)" % rel)


def check_res_paths(errors):
    for path in sorted(list((GAME / "scripts").rglob("*.gd")) + list(GAME.glob("scenes/**/*.tscn")) + list((GAME / "data").glob("*.json"))):
        text = path.read_text(errors="ignore")
        for m in RES_RE.finditer(text):
            target = GAME / m.group(1)[len("res://"):]
            if not target.exists():
                errors.append("%s names %s, which does not exist" % (path.relative_to(REPO), m.group(1)))


def check_animal_rows(errors):
    src = (GAME / "scripts" / "view" / "animal_sprite.gd").read_text()
    block = src[src.index("const ROWS := {"):src.index("}\n\n", src.index("const ROWS := {"))]
    from PIL import Image
    frame_of = {}
    for sp in json.loads((GAME / "data" / "balance.json").read_text())["animals"].values():
        if isinstance(sp, dict):
            for skin in list(sp.get("skins", [])) + list(sp.get("skins_m", [])):
                frame_of[skin] = int(sp.get("skin_art", {}).get(skin, {}).get("frame", sp.get("frame", 0)))
    for skin, body in re.findall(r'"(\w+)": \{([^}]*)\}', block):
        sheet = ASSETS / "animals" / ("%s.png" % skin)
        if not sheet.exists():
            errors.append("AnimalSprite.ROWS names %s, which has no sheet" % skin)
            continue
        img = Image.open(sheet).convert("RGBA")
        cw = ch = frame_of.get(skin) or sheets.detect_grid(img)[0]    # the frame the game draws with wins over a guess
        counts = sheets.frames_per_row(img, cw, ch)
        for anim, row, n in re.findall(r'"(\w+)": \[(\d+), (\d+)\]', body):
            row, n = int(row), int(n)
            if row >= len(counts) or n > counts[row]:
                errors.append("AnimalSprite.ROWS %s.%s wants row %d with %d frames; the sheet has %s" % (skin, anim, row, n, counts))


def unused():
    text = ""
    for path in list((GAME / "scripts").rglob("*.gd")) + list(GAME.glob("scenes/**/*.tscn")) + list((GAME / "data").glob("*.json")):
        text += path.read_text(errors="ignore")
    out = []
    for f in provenance():
        stem = Path(f["file"]).stem
        if stem not in text and Path(f["file"]).name not in text:
            out.append(f["file"])
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--unused", action="store_true", help="list imported files nothing names (may be built from ids at run time)")
    a = ap.parse_args()
    errors = []
    check_provenance(errors)
    check_res_paths(errors)
    check_animal_rows(errors)
    for e in errors:
        print("problem:", e)
    if a.unused:
        u = unused()
        print("%d imported files are not named literally anywhere (many are built from ids, e.g. icons/<item>.png):" % len(u))
        for f in u:
            print("  ", f)
    print("%d problems" % len(errors))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
