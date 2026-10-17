"""Smoke tests for the earlier asset tools, so later changes don't break them."""
import csv
import random
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from assetzip import REPO, AssetZip  # noqa: E402
import build_manifest  # noqa: E402
import miniworld_terrain  # noqa: E402
import puny_chargen  # noqa: E402
import puny_terrain  # noqa: E402
import render_tmj  # noqa: E402


def opaque_fraction(img):
    alpha = img.getchannel("A")
    return sum(1 for v in alpha.getdata() if v) / (img.width * img.height)


class ToolsTest(unittest.TestCase):
    def test_chargen_is_deterministic_and_sized(self):
        style = puny_chargen.Style()
        a = style.random_recipe(random.Random(42))
        b = style.random_recipe(random.Random(42))
        self.assertEqual(a, b)
        sheet = style.render(a)
        self.assertEqual(sheet.size, (32 * 29, 32 * 8))
        self.assertGreater(opaque_fraction(sheet), 0.05)

    def test_puny_terrain_tiles_exist(self):
        z = AssetZip("PUNY_CHARACTERS_v2.1.zip")
        _, tiles = puny_terrain.load_wangset(z)
        rng = random.Random(3)
        level = puny_terrain.repair(
            puny_terrain.quantise(puny_terrain.value_noise(21, 15, rng), 5), tiles)
        for y in range(14):
            for x in range(20):
                key = tuple(puny_terrain.CHAIN[level[yy][xx]]
                            for yy, xx in [(y, x), (y, x + 1), (y + 1, x + 1), (y + 1, x)])
                self.assertIn(key, tiles)

    def test_miniworld_biomes_render(self):
        sheet = AssetZip(miniworld_terrain.ZIP).image("terrain.png")
        for biome in miniworld_terrain.BIOMES:
            img, _ = miniworld_terrain.generate(16, 12, biome, random.Random(1), sheet)
            self.assertEqual(opaque_fraction(img), 1.0, biome)

    def test_render_tmj_resolves_parent_relative_images(self):
        # regression: '../tileset.png' paths used to render a blank map
        img = render_tmj.render(AssetZip("PUNY_WORLD_v1.zip"),
                                "PUNY_WORLD_v1/PUNY_WORLD_v1/Tiled/samplemap1.tmj")
        self.assertGreater(opaque_fraction(img), 0.99)

    def test_render_tmj_dungeon_fallback(self):
        img = render_tmj.render(AssetZip("PUNY_DUNGEON_v1.zip"),
                                "PUNY_DUNGEON_v1/Tiled/sample-map1.tmj")
        self.assertGreater(opaque_fraction(img), 0.5)

    def test_manifest_covers_exactly_the_assets(self):
        """Every top-level entry is a listed asset or explicitly not an asset, so a new
        doc or folder can't silently land in the asset manifest."""
        with open(REPO / "asset_manifest.csv") as f:
            sources = {r["archive"] for r in csv.DictReader(f)}
            f.seek(0)
            loose = {r["path"] for r in csv.DictReader(f) if r["archive"] == "(repo root)"}
        for p in REPO.iterdir():
            if p.name in build_manifest.NOT_ASSETS or p.name.startswith("."):
                continue
            listed = p.name in sources or p.name + "/" in sources or p.name in loose
            self.assertTrue(listed, f"{p.name} is neither in the manifest nor in NOT_ASSETS")


if __name__ == "__main__":
    unittest.main()
