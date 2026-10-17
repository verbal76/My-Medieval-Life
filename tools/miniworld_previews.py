"""Preview GIFs and PNG strips for data/miniworld_animations.json.

For each layout (red team sheet, or the only sheet), each animation gets:
  <layout>_<anim>.gif   all directions side by side, playing at frame_ms
  <layout>_strips.png   every animation/direction as a row of frames, drawn
                        with the origin alignment a game would use, on a
                        grid so offsets and clipping are easy to spot
"""
import io
import zipfile

from PIL import Image, ImageDraw

from assetzip import REPO

BG = (74, 104, 74, 255)
SCALE = 4


def frame_img(sheet, f):
    return sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))


def canvas_box(frames, cell):
    """Common box (left, top, right, bottom) relative to the body cell."""
    left = min(-f["origin"][0] for f in frames)
    top = min(-f["origin"][1] for f in frames)
    right = max(f["w"] - f["origin"][0] for f in frames)
    bottom = max(f["h"] - f["origin"][1] for f in frames)
    return left, top, max(right, cell), max(bottom, cell)


def pick_sheet(meta, layout):
    sheets = [s for s in meta["sheets"] if s["layout"] == layout]
    return next((s for s in sheets if s["team"] == "red"), sheets[0])


def write_all(meta, out):
    out.mkdir(parents=True, exist_ok=True)
    z = zipfile.ZipFile(REPO / meta["source"])
    for lname, layout in meta["layouts"].items():
        sheet = Image.open(io.BytesIO(z.read(pick_sheet(meta, lname)["file"]))).convert("RGBA")
        cell = layout["cell"]
        strip_rows = []
        for aname, a in layout["animations"].items():
            dirs = list(a["frames"])
            allf = [f for d in dirs for f in a["frames"][d]]
            l, t, r, b = canvas_box(allf, cell)
            bw, bh = r - l, b - t
            n = max(len(a["frames"][d]) for d in dirs)
            gif_frames = []
            for i in range(n):
                im = Image.new("RGBA", (bw * len(dirs), bh), BG)
                for k, d in enumerate(dirs):
                    fs = a["frames"][d]
                    f = fs[i % len(fs)]
                    im.alpha_composite(frame_img(sheet, f), (k * bw - l - f["origin"][0], -t - f["origin"][1]))
                gif_frames.append(im.resize((im.width * SCALE, im.height * SCALE), Image.NEAREST)
                                  .convert("P", palette=Image.ADAPTIVE))
            gif_frames[0].save(out / f"{lname}_{aname}.gif", save_all=True,
                               append_images=gif_frames[1:], loop=0,
                               duration=a["frame_ms"], disposal=2)
            for d in dirs:
                strip_rows.append((f"{aname}/{d}", a["frames"][d], (l, t, bw, bh)))
        # strips: one row per animation/direction, frames on an aligned grid
        cw = max(bw for _, _, (_, _, bw, _) in strip_rows)
        ch = max(bh for _, _, (_, _, _, bh) in strip_rows)
        cols = max(len(fs) for _, fs, _ in strip_rows)
        label_w = 120
        img = Image.new("RGBA", (label_w + cols * (cw * SCALE + 4), len(strip_rows) * (ch * SCALE + 4)),
                        (25, 25, 25, 255))
        d = ImageDraw.Draw(img)
        for row, (label, fs, (l, t, _, _)) in enumerate(strip_rows):
            y = row * (ch * SCALE + 4)
            d.text((4, y + 4), label, fill=(255, 255, 0))
            for i, f in enumerate(fs):
                tile = Image.new("RGBA", (cw, ch), BG)
                tile.alpha_composite(frame_img(sheet, f), (-l - f["origin"][0], -t - f["origin"][1]))
                big = tile.resize((cw * SCALE, ch * SCALE), Image.NEAREST)
                bx = label_w + i * (cw * SCALE + 4)
                img.paste(big, (bx, y))
                # mark the body cell so misaligned frames stand out
                ox, oy = (-l) * SCALE, (-t) * SCALE
                d.rectangle([bx + ox, y + oy, bx + ox + cell * SCALE - 1, y + oy + cell * SCALE - 1],
                            outline=(255, 255, 255, 70))
        img.save(out / f"{lname}_strips.png")
    print("previews written to", out)
