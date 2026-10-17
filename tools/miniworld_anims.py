"""Animation metadata for the Miniworld soldier and worker sprite sheets.

Writes data/miniworld_animations.json: for every soldier/worker sheet in
MiniWorldSprites.zip, which layout it uses, and for every layout each
animation's frames per direction as pixel rectangles, with timing.

Layouts were worked out by inspecting the sheets (see tools/README.md):
the 80x192 swordsman layout and its timings come from Shade's
Miniworld-Guide.docx; the rest follow the same conventions where the art
shows them, and anything not settled by the art is flagged "uncertain".
No frames are invented: every rectangle points at artwork in the sheet.

Frames are {"x", "y", "w", "h", "origin": [ox, oy]}. Most frames are one
cell; a few (spear thrusts) span two cells. `origin` is where the
character's own cell sits inside the frame, so a renderer draws the frame
at (cell_x - ox, cell_y - oy) and the body never jumps.

Usage:
    python3 tools/miniworld_anims.py            # write the JSON + validate
    python3 tools/miniworld_anims.py --previews # also GIFs/PNG strips in out/
"""
import argparse
import io
import json
import re
import zipfile
from pathlib import Path

from PIL import Image

from assetzip import REPO

ZIP = "MiniWorldSprites.zip"
ROOT = "MiniWorldSprites/Characters/"
OUT_JSON = REPO / "data" / "miniworld_animations.json"
DIRECTIONS = ["down", "up", "right", "left"]
STD = {"down": 0, "up": 1, "right": 2, "left": 3}   # usual row order in a 4-row block

# Shade's guide: idle 300, walk 200, attack 100, shield idle 300, shield hurt 100 (ms)
GUIDE_MS = {"idle": 300, "walk": 200, "attack": 100, "shield_idle": 300, "shield_hurt": 100}


def cells(rows, cols, base=0):
    """Single-cell frames: {dir: [(col, row, w, h, ox, oy), ...]}."""
    return {d: [(c, base + r, 1, 1, 0, 0) for c in cols] for d, r in rows.items()}


def anim(frames, ms, loop, timing="guide", uncertain=None, directional=True):
    return {"frames": frames, "ms": ms, "loop": loop, "timing": timing,
            "uncertain": uncertain, "directional": directional}


def idle_walk(cols=5, base=0):
    return {
        "idle": anim(cells(STD, range(0, 2), base), GUIDE_MS["idle"], True),
        "walk": anim(cells(STD, range(1, cols), base), GUIDE_MS["walk"], True),
    }


BALLISTA_NOTE = ("down/up may be swapped: in row 0 the bolt points up the screen, while in the "
                 "side rows the bolt points the way the ballista faces. Sprites fill their 16px cells "
                 "edge to edge, so edge_contact here is neighbouring frames touching, not clipping.")

LAYOUTS = {
    "swordsman": {
        "cell": 16, "size": [80, 192], "pattern": r"Soldiers/Melee/.*Swordsman",
        "animations": {
            **idle_walk(),
            "attack": anim(cells(STD, range(4), 4), GUIDE_MS["attack"], False),
            "shield_idle": anim(cells(STD, range(0, 2), 8), GUIDE_MS["shield_idle"], True),
            "shield_hurt": anim(cells(STD, range(1, 5), 8), GUIDE_MS["shield_hurt"], False),
        },
    },
    "assassin": {
        "cell": 16, "size": [80, 192], "pattern": r"Soldiers/Melee/.*Assasin",
        "animations": {
            **idle_walk(),
            # two 4-frame attacks per direction, in adjacent rows: down 4/5, up 6/7, right 8/9, left 10/11
            "attack": anim(cells({"down": 4, "up": 6, "right": 8, "left": 10}, range(4)),
                           GUIDE_MS["attack"], False, "assumed"),
            "attack_2": anim(cells({"down": 5, "up": 7, "right": 9, "left": 11}, range(4)),
                             GUIDE_MS["attack"], False, "assumed",
                             "second attack per direction; may be meant to follow 'attack' as a combo"),
        },
    },
    "spearman": {
        "cell": 16, "size": [80, 224], "pattern": r"Soldiers/Melee/.*Spearman",
        "animations": {
            **idle_walk(),
            # thrust frames span two cells; origin marks the body cell
            "attack": anim({
                "down": [(0, 4, 1, 1, 0, 0), (0, 6, 1, 2, 0, 0), (0, 8, 1, 2, 0, 0)],
                "up": [(1, 5, 1, 1, 0, 0), (1, 6, 1, 2, 0, 1), (1, 8, 1, 2, 0, 1)],
                "left": [(3, 4, 1, 1, 0, 0), (2, 5, 2, 1, 1, 0), (2, 6, 2, 1, 1, 0)],
                "right": [(2, 7, 2, 1, 0, 0), (2, 8, 2, 1, 0, 0), (2, 9, 2, 1, 0, 0)],
            }, GUIDE_MS["attack"], False, "assumed"),
            "shield_idle": anim(cells(STD, range(0, 2), 10), GUIDE_MS["shield_idle"], True),
            "shield_hurt": anim(cells(STD, range(1, 5), 10), GUIDE_MS["shield_hurt"], False),
        },
    },
    "axeman": {
        "cell": 16, "size": [96, 96], "pattern": r"Soldiers/Melee/.*Axeman",
        "animations": {
            **idle_walk(),
            # rows 4/5: one 6-pose sequence facing down, down, down, right, up, left
            "spin_attack": anim({"any": [(c, 5, 1, 1, 0, 0) for c in range(6)]},
                                GUIDE_MS["attack"], False, "assumed",
                                "read as a 360-degree spin; row 5 has slash trails", directional=False),
            "spin_attack_plain": anim({"any": [(c, 4, 1, 1, 0, 0) for c in range(6)]},
                                      GUIDE_MS["attack"], False, "assumed",
                                      "same poses as spin_attack without slash trails",
                                      directional=False),
        },
    },
    "bowman": {
        "cell": 16, "size": [80, 128], "pattern": r"Soldiers/Ranged/.*Bowman",
        "animations": {
            **idle_walk(),
            # attack rows run down, up, LEFT, RIGHT (arrow direction / pose match)
            "attack": anim(cells({"down": 4, "up": 5, "left": 6, "right": 7}, range(3)),
                           GUIDE_MS["attack"], False, "assumed"),
        },
    },
    "musketeer": {
        "cell": 16, "size": [80, 128], "pattern": r"Soldiers/Ranged/.*Musketeer",
        "animations": {
            **idle_walk(),
            "attack": anim(cells(STD, range(4), 4), GUIDE_MS["attack"], False, "assumed"),
        },
    },
    "mage": {
        "cell": 16, "size": [96, 128], "pattern": r"Soldiers/Ranged/.*Mage",
        "animations": {
            "idle": anim(cells(STD, range(0, 2)), GUIDE_MS["idle"], True, "assumed",
                         "only 4 columns; idle/walk split follows the pack convention"),
            "walk": anim(cells(STD, range(1, 4)), GUIDE_MS["walk"], True, "assumed",
                         "only 4 columns; idle/walk split follows the pack convention"),
            # cast rows run down, up, LEFT, RIGHT (hood opening / pose match)
            "cast": anim(cells({"down": 4, "up": 5, "left": 6, "right": 7}, range(6)),
                         GUIDE_MS["attack"], False, "assumed"),
        },
    },
    "knight": {
        "cell": 32, "size": [128, 384], "pattern": r"Soldiers/Mounted/.*Knight",
        "animations": {
            # 32px cells; per direction a block of 3 rows: walk, idle, attack.
            # Blocks run down, right, left, up (horse heading).
            "walk": anim(cells({"down": 0, "right": 3, "left": 6, "up": 9}, range(4)),
                         GUIDE_MS["walk"], True, "assumed",
                         "walk/idle rows inferred: the idle row alternates two poses in every block"),
            "idle": anim(cells({"down": 1, "right": 4, "left": 7, "up": 10}, range(4)),
                         GUIDE_MS["idle"], True, "assumed",
                         "walk/idle rows inferred: the idle row alternates two poses in every block"),
            "attack": anim(cells({"down": 2, "right": 5, "left": 8, "up": 11}, range(4)),
                           GUIDE_MS["attack"], False, "assumed"),
        },
    },
    "ballista": {
        "cell": 16, "size": [112, 64], "pattern": r"Soldiers/Ranged/Ballista",
        "animations": {
            "fire": anim(cells(STD, range(0, 3)), GUIDE_MS["attack"], False, "assumed",
                         BALLISTA_NOTE),
            "move": anim(cells(STD, range(3, 7)), GUIDE_MS["walk"], True, "assumed", BALLISTA_NOTE),
        },
    },
    "farmer": {
        "cell": 16, "size": [80, 192], "pattern": r"Workers/.*Farmer",
        "animations": {
            **idle_walk(),
            "carry_idle": anim(cells(STD, range(0, 2), 4), GUIDE_MS["idle"], True, "assumed",
                               "arms held out as if carrying; nothing carried is drawn"),
            "carry_walk": anim(cells(STD, range(1, 5), 4), GUIDE_MS["walk"], True, "assumed",
                               "arms held out as if carrying; nothing carried is drawn"),
            "work": anim(cells(STD, range(3), 8), GUIDE_MS["attack"], False, "assumed",
                         "tool swing; the 'up' row (9) reads front-facing in the art"),
        },
    },
}

TEAMS = ("Template", "Red", "Cyan", "Lime", "Purple")


def to_rect(frame, cell):
    c, r, w, h, ox, oy = frame
    return {"x": c * cell, "y": r * cell, "w": w * cell, "h": h * cell, "origin": [ox * cell, oy * cell]}


def find_sheets(z):
    sheets = []
    for name in sorted(z.namelist()):
        if not (name.startswith(ROOT) and name.endswith(".png")):
            continue
        rel = name[len(ROOT):]
        for layout, spec in LAYOUTS.items():
            if re.search(spec["pattern"], rel):
                stem = Path(rel).stem
                team = next((t for t in TEAMS if stem.endswith(t) or stem.startswith(t)), None)
                sheets.append({"file": name, "layout": layout, "team": (team or "none").lower()})
    return sheets


def build():
    out = {
        "format": "miniworld-animations/1",
        "source": ZIP,
        "directions": DIRECTIONS,
        "about": ("Frames are pixel rectangles in the sheet. Draw a frame at "
                  "(cell_x - origin[0], cell_y - origin[1]) where (cell_x, cell_y) is the "
                  "top-left of the character's cell-sized footprint. 'any' = not directional. "
                  "timing 'guide' = Shade's Miniworld guide; 'assumed' = guide value reused."),
        "layouts": {},
        "sheets": find_sheets(zipfile.ZipFile(REPO / ZIP)),
    }
    for name, spec in LAYOUTS.items():
        anims = {}
        for aname, a in spec["animations"].items():
            anims[aname] = {
                "loop": a["loop"], "frame_ms": a["ms"], "timing": a["timing"],
                "directional": a["directional"], "uncertain": a["uncertain"],
                "frames": {d: [to_rect(f, spec["cell"]) for f in fs] for d, fs in a["frames"].items()},
            }
        out["layouts"][name] = {"cell": spec["cell"], "sheet_size": spec["size"], "animations": anims}
    return out


def validate(meta):
    """Return a list of problems; also attach per-frame edge-contact notes."""
    z = zipfile.ZipFile(REPO / meta["source"])
    problems, notes = [], {}
    for sheet in meta["sheets"]:
        layout = meta["layouts"][sheet["layout"]]
        img = Image.open(io.BytesIO(z.read(sheet["file"]))).convert("RGBA")
        if list(img.size) != layout["sheet_size"]:
            problems.append(f"{sheet['file']}: size {img.size} != {layout['sheet_size']}")
            continue
        alpha = img.getchannel("A").load()
        cell = layout["cell"]
        for aname, a in layout["animations"].items():
            for d, frames in a["frames"].items():
                for i, f in enumerate(frames):
                    x0, y0, x1, y1 = f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]
                    inside = [(x, y) for x in range(x0, x1) for y in range(y0, y1) if alpha[x, y]]
                    if not inside:
                        problems.append(f"{sheet['file']} {aname}/{d}/{i}: empty frame")
                        continue
                    # opaque pixels just outside the frame touching opaque pixels inside
                    leak = 0
                    for x, y in inside:
                        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                            if not (x0 <= nx < x1 and y0 <= ny < y1) and \
                                    0 <= nx < img.width and 0 <= ny < img.height and alpha[nx, ny]:
                                leak += 1
                    if leak:
                        notes.setdefault((sheet["layout"], aname, d, i), []).append(leak)
                    # in multi-cell frames the non-body cells may hold a weapon, not a sprite
                    ox, oy = f["origin"]
                    for cx in range(x0, x1, cell):
                        for cy in range(y0, y1, cell):
                            if (cx - x0, cy - y0) == (ox, oy):
                                continue
                            n = sum(1 for x in range(cx, cx + cell) for y in range(cy, cy + cell) if alpha[x, y])
                            if n > cell * cell // 4:
                                problems.append(f"{sheet['file']} {aname}/{d}/{i}: cell ({cx},{cy}) "
                                                f"holds {n}px, looks like another sprite")
    return problems, notes


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--previews", action="store_true")
    ap.add_argument("-o", "--out", default="out/miniworld_anims")
    args = ap.parse_args()

    meta = build()
    problems, notes = validate(meta)
    for (layout, aname, d, i), leaks in sorted(notes.items()):
        f = meta["layouts"][layout]["animations"][aname]
        f.setdefault("edge_contact", []).append(
            {"direction": d, "frame": i, "max_px": max(leaks),
             "note": "artwork touches pixels outside this frame; up to max_px edge pixels may be cut"})
    OUT_JSON.parent.mkdir(exist_ok=True)
    OUT_JSON.write_text(json.dumps(meta, indent=1) + "\n")
    print(f"wrote {OUT_JSON.relative_to(REPO)}: {len(meta['sheets'])} sheets, "
          f"{len(meta['layouts'])} layouts, {len(problems)} problems, {len(notes)} edge-contact frames")
    for p in problems:
        print("PROBLEM:", p)
    if args.previews:
        import miniworld_previews
        miniworld_previews.write_all(meta, Path(args.out))
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
