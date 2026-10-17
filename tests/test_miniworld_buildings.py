"""Tests for data/miniworld_buildings.json."""
import io
import json
import sys
import unittest
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import miniworld_buildings as mb  # noqa: E402
from assetzip import REPO  # noqa: E402


class MiniworldBuildingsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.meta = json.loads(mb.OUT_JSON.read_text())
        z = zipfile.ZipFile(REPO / mb.ZIP)
        cls.sheets = {n: np.array(Image.open(io.BytesIO(z.read(n))).convert("RGBA"))
                      for n in z.namelist() if n.startswith(mb.ROOT) and n.endswith(".png")}

    def test_every_guide_building_is_listed(self):
        names = [n for _, n, _ in mb.guide_entries()]
        self.assertEqual(len(names), 28)
        self.assertEqual([b["name"] for b in self.meta["buildings"]], names)
        self.assertTrue(all(b["variants"] for b in self.meta["buildings"]))

    def test_rects_are_in_bounds_and_not_empty(self):
        def check(file, rect):
            s = self.sheets[file]
            x, y, w, h = rect
            self.assertTrue(0 <= x and x + w <= s.shape[1] and 0 <= y and y + h <= s.shape[0], (file, rect))
            self.assertGreater((s[y:y + h, x:x + w, 3] > 0).sum(), 20, (file, rect))
        for b in self.meta["buildings"]:
            for v in b["variants"]:
                check(v["file"], v["rect"])
                for t in v["teams"].values():
                    check(t["file"], t["rect"])
        for u in self.meta["unidentified"]:
            for f in u["files"]:
                check(f, u["rect"])

    def test_exact_matches_reproduce_the_guide(self):
        """Each guide tile is found pixel for pixel where the atlas says."""
        guide = {n: mb.rgba(png) for _, n, png in mb.guide_entries()}
        for b in self.meta["buildings"]:
            if b["uncertain"]:
                continue
            pic = guide[b["name"]]
            found = 0
            for v in b["variants"]:
                x, y, w, h = v["rect"]
                sprite = self.sheets[v["matched_in"]][y:y + h, x:x + w].astype(np.int16)
                # the sprite must appear inside the guide picture; some guide crops
                # are a pixel short or long, so allow a 1px overhang at either side
                for oy in range(-1, pic.shape[0] - h + 2):
                    for ox in range(-1, pic.shape[1] - w + 2):
                        gx0, gy0 = max(ox, 0), max(oy, 0)
                        gx1, gy1 = min(ox + w, pic.shape[1]), min(oy + h, pic.shape[0])
                        if gx1 - gx0 < w - 1 or gy1 - gy0 < h - 1:
                            continue
                        win = pic[gy0:gy1, gx0:gx1]
                        part = sprite[gy0 - oy:gy1 - oy, gx0 - ox:gx1 - ox]
                        if ((win[..., 3] > 0) == (part[..., 3] > 0)).all() and \
                                (win[..., :3][win[..., 3] > 0] == part[..., :3][part[..., 3] > 0]).all():
                            found += 1
                            break
                    else:
                        continue
                    break
            self.assertEqual(found, len(b["variants"]), b["name"])

    def test_uncertain_is_explicit(self):
        unsure = {b["name"] for b in self.meta["buildings"] if b["uncertain"]}
        self.assertEqual(unsure, {"Mining Shaft / Quarry"})
        for b in self.meta["buildings"]:
            for v in b["variants"]:
                self.assertEqual(v["match"] < 1.0, bool(b["uncertain"]), b["name"])

    def test_no_sprite_is_both_named_and_unidentified(self):
        named = {(v["file"], tuple(v["rect"])) for b in self.meta["buildings"] for v in b["variants"]}
        named |= {(t["file"], tuple(t["rect"])) for b in self.meta["buildings"]
                  for v in b["variants"] for t in v["teams"].values()}

        def tiles(f, r):
            return {(f, x, y) for x in range(r[0], r[0] + r[2], 16) for y in range(r[1], r[1] + r[3], 16)}
        named_tiles = set().union(*(tiles(f, r) for f, r in named))
        for u in self.meta["unidentified"]:
            for f in u["files"]:
                self.assertFalse(tiles(f, u["rect"]) & named_tiles, (u["sheet_hint"], u["rect"]))

    def test_team_versions_share_the_silhouette(self):
        for b in self.meta["buildings"]:
            for v in b["variants"]:
                for t in v["teams"].values():
                    self.assertGreaterEqual(t["silhouette_iou"], 0.85)


if __name__ == "__main__":
    unittest.main()
