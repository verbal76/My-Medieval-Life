"""WEAPON-CATALOG-01 (Build 22): the generated weapon catalogue matches its table, covers the whole master sheet, and every
piece the catalogue lets the player order has a recipe the makers can work."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import build_weapons  # noqa: E402
import check_resources  # noqa: E402


class GearCatalogueTest(unittest.TestCase):
    def test_catalogue_is_current(self):
        self.assertEqual(build_weapons.render(), (ROOT / "game/data/weapon_catalogue.json").read_text(),
                         "run python3 tools/build_weapons.py --write")

    def test_whole_sheet(self):
        cat = json.loads((ROOT / "game/data/weapon_catalogue.json").read_text())
        table = json.loads((ROOT / "game/data/weapon_types.json").read_text())
        self.assertEqual(len(cat["items"]), len(table["types"]) * len(table["metals"]) * 30)
        cells = {(it["icon"][0], it["icon"][1], it["icon"][2]) for it in cat["items"].values()}
        self.assertEqual(len(cells), len(cat["items"]), "every weapon is its own cell of the sheet")
        for sheet in {c[0] for c in cells}:
            self.assertEqual(len([c for c in cells if c[0] == sheet]), 24 * 20, sheet + ": all 480 cells used")
        for iid, it in cat["items"].items():
            r = cat["recipes"]["forge_" + iid]
            self.assertTrue(1 <= r["level"] <= 10 and r["skill"] == "smithing" and r["station"] == "anvil", iid)
            for k in it["order"].get("bring", {}):
                self.assertIn(k, r["in"], iid)
            if it["class"] == "rare":
                self.assertTrue(it["order"].get("bring"), iid + ": a rare weapon is a commission")

    def test_resources_check_clean(self):
        ctx = check_resources.load()
        self.assertEqual(check_resources.problems(ctx), [])

    def test_tusks_and_antlers_have_only_animal_sources(self):
        ctx = check_resources.load()
        for item in ("boar_tusk", "antler"):
            kinds = {s[0] for s in check_resources.sources_of(ctx, item)}
            self.assertEqual(kinds, {"node"}, item)


if __name__ == "__main__":
    unittest.main()
