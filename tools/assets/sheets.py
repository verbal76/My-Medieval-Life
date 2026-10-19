"""Sprite-sheet library for the asset integration pipeline (asset-integration-pipeline skill).

Reads images from any pack source (a zip in the repository root, a loose folder, or a file or folder in
private-assets/), finds a sheet's frame grid, extracts frames, scales pixel art and draws contact sheets
with a pixel grid for inspection (and for the owner to redraw in Aseprite). Standard library + Pillow.

    python3 tools/assets/sheets.py grid   <source> <member>          # frame size and frames per row
    python3 tools/assets/sheets.py objects <source> <member>         # the separate sprites of an atlas
    python3 tools/assets/sheets.py contact <source> <member> OUT.png [--cell N] [--zoom Z]
    python3 tools/assets/sheets.py scale  <source> <member> OUT.png --factor F [--method nearest|box]

<source> is a path relative to the repository root ("PunyMonsters.zip", "MiniFolks Forest Animals",
"private-assets/craftpix-....zip"); <member> is the file inside it.
"""
import argparse
import io
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[2]
IMAGE_EXT = (".png", ".gif", ".bmp", ".jpg", ".jpeg", ".webp")


# ---------------------------------------------------------------- sources -----------------------
class Source:
    """One pack: a zip (read in place) or a folder (read in place). Nothing is ever written to it."""

    def __init__(self, rel):
        self.rel = rel
        self.path = REPO / rel
        self.zip = zipfile.ZipFile(self.path) if self.path.is_file() and self.path.suffix.lower() == ".zip" else None

    def exists(self):
        return self.path.exists()

    def members(self):
        if self.zip is not None:
            return sorted(n for n in self.zip.namelist() if not n.endswith("/") and "__MACOSX" not in n)
        if self.path.is_dir():
            return sorted(str(p.relative_to(self.path)).replace("\\", "/") for p in self.path.rglob("*") if p.is_file())
        return [self.path.name] if self.path.is_file() else []

    def read(self, member):
        if self.zip is not None:
            return self.zip.read(member)
        if self.path.is_dir():
            return (self.path / member).read_bytes()
        return self.path.read_bytes()

    def size(self, member):
        if self.zip is not None:
            return self.zip.getinfo(member).file_size
        return (self.path / member).stat().st_size if self.path.is_dir() else self.path.stat().st_size

    def image(self, member):
        return Image.open(io.BytesIO(self.read(member))).convert("RGBA")


# ---------------------------------------------------------------- grids -------------------------
CANDIDATES = (8, 16, 17, 20, 24, 32, 40, 48, 64, 80, 96, 128)


def _line_fill(px, horizontal, at, length, alpha):
    """The share of a row or column's pixels that are visible."""
    if horizontal:
        return sum(1 for x in range(length) if px[x, at][3] > alpha) / float(length)
    return sum(1 for y in range(length) if px[at, y][3] > alpha) / float(length)


def detect_grid(img, alpha=8, max_fill=0.08, min_clear=0.85):
    """A first guess at the frame size of a sheet: (cell_w, cell_h). It is right for most sheets, but a
    sheet whose sprites fit several grids can fool it (MiniFolks' fox reads as 24 px instead of 32): always
    confirm with `contact` and record the frame size the game uses in its data (balance.json "frame",
    the import spec); tools/assets/check_assets.py checks against the recorded size. The smallest candidate size that divides the sheet and
    whose cell boundary lines are nearly empty (at least min_clear of them under max_fill visible pixels;
    packed sheets let a tail or shadow touch an edge); the whole sheet when none fits. Deterministic."""
    w, h = img.size
    px = img.load()

    def ok(c, size, other, horizontal, need=min_clear):
        if size % c != 0 or c >= size:
            return False
        # a boundary is clear when the line on either side of it is (a sprite may touch one edge of its cell)
        bounds = list(range(1, size // c))
        clear = sum(1 for k in bounds if min(_line_fill(px, horizontal, k * c - 1, other, alpha), _line_fill(px, horizontal, k * c, other, alpha)) <= max_fill)
        return clear >= need * len(bounds)

    def filled(cw_, ch_):
        cells = [(c, r) for r in range(h // ch_) for c in range(w // cw_)]
        return sum(1 for c, r in cells if img.crop((c * cw_, r * ch_, c * cw_ + cw_, r * ch_ + ch_)).getbbox()) / float(len(cells))

    # of the sizes whose boundaries are clear, the one leaving fewest empty cells (a small sprite centred in a
    # wide frame also clears a finer grid, which would leave two empty cells beside each frame); ties: smaller
    xs = [c for c in CANDIDATES if ok(c, w, h, False)] or [w]
    cw = max(xs, key=lambda c: (round(filled(c, h), 2), -c))
    # frames are square in most packs: rows of the column size win when their boundaries are mostly clear
    # (a half-empty frame would otherwise split into two thin rows)
    if cw < w and h % cw == 0 and (h == cw or ok(cw, h, w, True, min_clear * 0.6)):
        return cw, cw
    ys = [c for c in CANDIDATES if ok(c, h, w, True)] or [h]
    ch = max(ys, key=lambda c: (round(filled(cw, c), 2), -c))
    if filled(cw, h) >= filled(cw, ch):
        ch = h                                  # a strip: one row of frames
    return cw, ch


def common_strip_width(imgs, alpha=8, max_fill=0.08):
    """For a set of one-row strips from the same pack (idle, walk, attack...), the largest frame width that
    divides every strip and cuts none of their sprites: one strip alone is ambiguous (a narrow sprite in a
    wide frame also fits a finer grid), the set is not. None when no candidate fits all."""
    fits = []
    for c in CANDIDATES:
        good = True
        for img in imgs:
            w, h = img.size
            if w % c != 0:
                good = False
                break
            px = img.load()
            for k in range(1, w // c):
                if _line_fill(px, False, k * c, h, alpha) > max_fill:
                    good = False
                    break
            if not good:
                break
        if good:
            fits.append(c)
    return max(fits) if fits else None


def find_objects(img, alpha=8, gap=1):
    """The separate sprites of an atlas without a grid (props, plants, crates), as boxes (x0, y0, x1, y1),
    by recursive cuts along fully transparent rows and columns (an XY cut), top to bottom, left to right."""
    px = img.load()

    def empty_row(y, x0, x1):
        return all(px[x, y][3] <= alpha for x in range(x0, x1))

    def empty_col(x, y0, y1):
        return all(px[x, y][3] <= alpha for y in range(y0, y1))

    def runs(lo, hi, empty):
        out, start = [], None
        for i in range(lo, hi):
            if not empty(i):
                start = i if start is None else start
            elif start is not None:
                out.append((start, i))
                start = None
        if start is not None:
            out.append((start, hi))
        return out

    def cut(x0, y0, x1, y1, horizontal, depth):
        bands = runs(y0, y1, lambda y: empty_row(y, x0, x1)) if horizontal else runs(x0, x1, lambda x: empty_col(x, y0, y1))
        if len(bands) <= 1 and depth > 0:
            box = img.crop((x0, y0, x1, y1)).getbbox()
            return [(x0 + box[0], y0 + box[1], x0 + box[2], y0 + box[3])] if box else []
        out = []
        for a, b in bands:
            if horizontal:
                out.extend(cut(x0, a, x1, b, False, depth + 1))
            else:
                out.extend(cut(a, y0, b, y1, True, depth + 1))
        return out

    return cut(0, 0, img.width, img.height, True, 0)


def frames_per_row(img, cw, ch):
    """For each row of cells, the number of cells up to the last one with any content."""
    out = []
    for r in range(img.height // ch):
        n = 0
        for c in range(img.width // cw):
            if img.crop((c * cw, r * ch, c * cw + cw, r * ch + ch)).getbbox():
                n = c + 1
        out.append(n)
    return out


def frame(img, cw, ch, col, row):
    return img.crop((col * cw, row * ch, col * cw + cw, row * ch + ch))


def content_box(img):
    """The visible pixels' bounds (x0, y0, x1, y1), or None for an empty image."""
    return img.getbbox()


# ---------------------------------------------------------------- scaling -----------------------
def scale(img, factor, method="nearest", alpha_cut=128):
    """Scale pixel art by `factor`. nearest: exact copies (integer factors keep every pixel). box: area
    average, for downscaling detailed art (e.g. 96 px animals to the 16 px world); the alpha is then cut at
    alpha_cut so edges stay hard and nothing goes half-transparent. Deterministic."""
    w, h = img.size
    size = (max(1, round(w * factor)), max(1, round(h * factor)))
    if method == "nearest" or factor >= 1.0:
        return img.resize(size, Image.NEAREST)
    k = round(1.0 / factor)
    if abs(1.0 / k - factor) < 1e-9 and w % k == 0 and h % k == 0:
        out = img.reduce(k)
    else:
        out = img.resize(size, Image.BOX)
    r, g, b, a = out.split()
    a = a.point(lambda v: 255 if v >= alpha_cut else 0)
    return Image.merge("RGBA", (r, g, b, a))


def scale_sheet(img, cw, ch, factor, method="nearest"):
    """Scale every frame of a sheet separately (so frames never bleed into each other) and reassemble."""
    cols, rows = img.width // cw, img.height // ch
    ncw, nch = max(1, round(cw * factor)), max(1, round(ch * factor))
    out = Image.new("RGBA", (cols * ncw, rows * nch), (0, 0, 0, 0))
    for r in range(rows):
        for c in range(cols):
            out.paste(scale(frame(img, cw, ch, c, r), factor, method), (c * ncw, r * nch))
    return out


# ---------------------------------------------------------------- contact sheets ----------------
def contact(img, cw, ch, zoom=6, bg=(52, 56, 64, 255), grid=(90, 96, 108, 255), cell_line=(230, 180, 60, 255)):
    """An enlarged copy with a one-pixel grid over every source pixel and a strong line around each frame,
    labelled column,row: for inspecting frames and for redrawing in Aseprite."""
    w, h = img.size
    big = Image.new("RGBA", (w * zoom, h * zoom), bg)
    big.paste(img.resize((w * zoom, h * zoom), Image.NEAREST), (0, 0), img.resize((w * zoom, h * zoom), Image.NEAREST))
    d = ImageDraw.Draw(big)
    if zoom >= 4:
        for x in range(0, w * zoom, zoom):
            d.line([(x, 0), (x, h * zoom)], fill=grid)
        for y in range(0, h * zoom, zoom):
            d.line([(0, y), (w * zoom, y)], fill=grid)
    for c in range(0, w // cw + 1):
        d.line([(c * cw * zoom, 0), (c * cw * zoom, h * zoom)], fill=cell_line, width=2)
    for r in range(0, h // ch + 1):
        d.line([(0, r * ch * zoom), (w * zoom, r * ch * zoom)], fill=cell_line, width=2)
    for r in range(h // ch):
        for c in range(w // cw):
            d.text((c * cw * zoom + 3, r * ch * zoom + 2), "%d,%d" % (c, r), fill=(255, 255, 255, 255))
    return big


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["grid", "objects", "contact", "scale"])
    ap.add_argument("source")
    ap.add_argument("member")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--cell", type=int, default=0)
    ap.add_argument("--zoom", type=int, default=6)
    ap.add_argument("--factor", type=float, default=1.0)
    ap.add_argument("--method", default="nearest")
    a = ap.parse_args()
    img = Source(a.source).image(a.member)
    cw, ch = (a.cell, a.cell) if a.cell else detect_grid(img)
    if a.cmd == "objects":
        boxes = find_objects(img)
        print("%d objects" % len(boxes))
        for b in boxes:
            print("  %s  %dx%d" % (b, b[2] - b[0], b[3] - b[1]))
    elif a.cmd == "grid":
        print("size %dx%d  frame %dx%d  frames per row %s  content %s" % (img.width, img.height, cw, ch, frames_per_row(img, cw, ch), content_box(img)))
    elif a.cmd == "contact":
        contact(img, cw, ch, a.zoom).save(a.out)
        print("wrote", a.out)
    else:
        scale_sheet(img, cw, ch, a.factor, a.method).save(a.out)
        print("wrote", a.out)


if __name__ == "__main__":
    main()
