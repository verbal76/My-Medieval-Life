"""game/data/overworld_tiles.json is what tools/build_overworld_tiles.py writes, and complete."""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import build_overworld_tiles  # noqa: E402


class OverworldTilesTest(unittest.TestCase):
    def test_committed_file_is_generated(self):
        committed = json.loads(build_overworld_tiles.OUT.read_text())
        self.assertEqual(committed, build_overworld_tiles.build())

    def test_tables_are_complete(self):
        d = build_overworld_tiles.build()
        self.assertEqual(d["format"], "mml-overworld-tiles/1")
        self.assertEqual(len(d["cliff"]), 16)
        self.assertTrue(all(d["cliff"]), "a tile for every grass/cliff corner combination")
        self.assertEqual(d["cliff"][0], d["grass"])
        self.assertEqual(len(d["dirt_path"]), 16)
        self.assertTrue(all(d["dirt_path"][1:]), "a road tile for every set of joined sides")
        self.assertEqual({t["group"] for t in d["trees"]}, {"leafy", "autumn", "mixed", "conifer"})


if __name__ == "__main__":
    unittest.main()
