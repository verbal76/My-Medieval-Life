"""Tests for data/miniworld_animations.json and the tool that writes it."""
import json
import sys
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import miniworld_anims as ma  # noqa: E402
from assetzip import REPO  # noqa: E402


class MiniworldAnimsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.meta = ma.build()
        cls.committed = json.loads(ma.OUT_JSON.read_text())

    def test_committed_json_is_current(self):
        fresh = json.loads(json.dumps(self.meta))
        # edge_contact notes are added by main(); compare everything else
        for layout in self.committed["layouts"].values():
            for a in layout["animations"].values():
                a.pop("edge_contact", None)
        self.assertEqual(fresh, self.committed)

    def test_validation_passes(self):
        problems, _ = ma.validate(self.meta)
        self.assertEqual(problems, [])

    def test_every_soldier_and_worker_sheet_is_mapped(self):
        names = zipfile.ZipFile(REPO / ma.ZIP).namelist()
        wanted = {n for n in names if n.endswith(".png") and
                  (n.startswith(ma.ROOT + "Soldiers/") or n.startswith(ma.ROOT + "Workers/"))}
        mapped = {s["file"] for s in self.meta["sheets"]}
        self.assertEqual(wanted, mapped)
        self.assertEqual(len(self.meta["sheets"]), 44)
        self.assertTrue(all(s["team"] != "none" or s["layout"] == "ballista" for s in self.meta["sheets"]))

    def test_frames_in_bounds_with_sane_origins(self):
        for lname, layout in self.meta["layouts"].items():
            w, h = layout["sheet_size"]
            cell = layout["cell"]
            for aname, a in layout["animations"].items():
                dirs = set(a["frames"])
                self.assertEqual(dirs, set(ma.DIRECTIONS) if a["directional"] else {"any"}, (lname, aname))
                self.assertGreater(a["frame_ms"], 0)
                for frames in a["frames"].values():
                    self.assertTrue(frames)
                    for f in frames:
                        self.assertTrue(0 <= f["x"] and f["x"] + f["w"] <= w and 0 <= f["y"] and f["y"] + f["h"] <= h)
                        ox, oy = f["origin"]
                        self.assertTrue(0 <= ox <= f["w"] - cell and 0 <= oy <= f["h"] - cell, (lname, aname, f))

    def test_guide_layout_matches_guide(self):
        sw = self.meta["layouts"]["swordsman"]["animations"]
        self.assertEqual([f["x"] // 16 for f in sw["walk"]["frames"]["down"]], [1, 2, 3, 4])
        self.assertEqual(sw["idle"]["frame_ms"], 300)
        self.assertEqual(sw["attack"]["frame_ms"], 100)
        self.assertEqual(sw["shield_hurt"]["frames"]["left"][0]["y"], 11 * 16)


if __name__ == "__main__":
    unittest.main()
