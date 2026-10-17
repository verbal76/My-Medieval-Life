"""Render Tiled .tmj maps from the asset archives to PNG, headlessly.

Handles orthogonal maps, external .tsx tilesets, group layers, layer offsets,
hidden layers and the flip flags in tile GIDs.

Usage:
    python3 tools/render_tmj.py PUNY-WORLD-PAID_v1.zip \
        PUNY-WORLD-PAID_v1/Tiled/sample-village-1.tmj -o out/maps
    python3 tools/render_tmj.py --all -o out/maps
"""
import argparse
import json
import posixpath
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

from PIL import Image

from assetzip import REPO, AssetZip

FLIP_H, FLIP_V, FLIP_D = 0x80000000, 0x40000000, 0x20000000


class Tileset:
    def __init__(self, z, tsx_path, firstgid):
        root = ET.fromstring(z.text(tsx_path))
        self.firstgid = firstgid
        self.tw, self.th = int(root.get("tilewidth")), int(root.get("tileheight"))
        self.cols = int(root.get("columns"))
        self.count = int(root.get("tilecount"))
        img = root.find("image").get("source")
        self.image = z.image(posixpath.join(posixpath.dirname(tsx_path), img))
        self._cache = {}

    def tile(self, local):
        if local not in self._cache:
            x, y = (local % self.cols) * self.tw, (local // self.cols) * self.th
            self._cache[local] = self.image.crop((x, y, x + self.tw, y + self.th))
        return self._cache[local]


def render(z, tmj_path):
    m = json.loads(z.text(tmj_path))
    if m.get("orientation") != "orthogonal":
        raise ValueError(f"{tmj_path}: only orthogonal maps are supported")
    base = posixpath.dirname(tmj_path)
    tilesets = []
    for t in m["tilesets"]:
        path = posixpath.normpath(posixpath.join(base, t["source"]))
        # some sample maps point at "../x.tsx" when x.tsx sits next to the map
        fallback = posixpath.join(base, posixpath.basename(t["source"]))
        for candidate in (path, fallback):
            if z.exists(candidate):
                tilesets.append(Tileset(z, candidate, t["firstgid"]))
                break
        else:
            print(f"warning: {tmj_path}: tileset {t['source']} not in archive")
    tilesets.sort(key=lambda t: t.firstgid)
    tw, th = m["tilewidth"], m["tileheight"]
    canvas = Image.new("RGBA", (m["width"] * tw, m["height"] * th))

    def find(gid):
        ts = None
        for t in tilesets:
            if t.firstgid <= gid:
                ts = t
        return ts

    def draw(layers, ox=0, oy=0):
        for layer in layers:
            if not layer.get("visible", True):
                continue
            lx = ox + layer.get("offsetx", 0)
            ly = oy + layer.get("offsety", 0)
            if layer["type"] == "group":
                draw(layer["layers"], lx, ly)
            elif layer["type"] == "tilelayer":
                w = layer["width"]
                for i, raw in enumerate(layer["data"]):
                    gid = raw & ~(FLIP_H | FLIP_V | FLIP_D)
                    if not gid:
                        continue
                    ts = find(gid)
                    if ts is None or gid - ts.firstgid >= ts.count:
                        continue
                    im = ts.tile(gid - ts.firstgid)
                    if raw & FLIP_D:
                        im = im.transpose(Image.TRANSPOSE)
                    if raw & FLIP_H:
                        im = im.transpose(Image.FLIP_LEFT_RIGHT)
                    if raw & FLIP_V:
                        im = im.transpose(Image.FLIP_TOP_BOTTOM)
                    x = (i % w) * tw + int(lx)
                    y = (i // w) * th + int(ly) + th - im.height  # tiles anchor bottom-left
                    canvas.alpha_composite(im, (max(x, 0), max(y, 0)))

    draw(m["layers"])
    return canvas


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("zip", nargs="?")
    ap.add_argument("tmj", nargs="?")
    ap.add_argument("--all", action="store_true", help="render every orthogonal .tmj in every zip")
    ap.add_argument("-o", "--out", default="out/maps")
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()

    jobs = []
    if args.all:
        for zp in sorted(REPO.glob("*.zip")):
            for name in zipfile.ZipFile(zp).namelist():
                if name.endswith(".tmj"):
                    jobs.append((zp.name, name))
    elif args.zip and args.tmj:
        jobs.append((args.zip, args.tmj))
    else:
        ap.error("give ZIP and TMJ, or --all")

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for zname, tmj in jobs:
        try:
            img = render(AssetZip(zname), tmj)
        except ValueError as e:
            print("skip:", e)
            continue
        dest = out / f"{Path(zname).stem}__{Path(tmj).stem}.png"
        bg = Image.new("RGBA", img.size, (24, 20, 37, 255))
        bg.alpha_composite(img)
        bg.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST).save(dest)
        print("wrote", dest)


if __name__ == "__main__":
    main()
