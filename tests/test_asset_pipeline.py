"""Tests for the asset integration pipeline (tools/assets): grid detection, objects, scaling, validation."""
import subprocess
import sys
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools" / "assets"))
import sheets  # noqa: E402


def _sheet(cols, rows, cell, box):
    """A transparent sheet with an opaque rectangle `box` (x0, y0, x1, y1, inside the cell) in every cell."""
    img = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for r in range(rows):
        for c in range(cols):
            x, y = c * cell, r * cell
            d.rectangle([x + box[0], y + box[1], x + box[2], y + box[3]], fill=(200, 50, 50, 255))
    return img


class GridTest(unittest.TestCase):
    def test_square_frames(self):
        img = _sheet(6, 4, 32, (6, 10, 25, 30))
        self.assertEqual(sheets.detect_grid(img), (32, 32))
        self.assertEqual(sheets.frames_per_row(img, 32, 32), [6, 6, 6, 6])

    def test_half_empty_frames_stay_square(self):
        # sprites only in the lower half of each 32 px frame (as MiniFolks): not 16 px rows
        img = _sheet(4, 3, 32, (8, 18, 23, 29))
        self.assertEqual(sheets.detect_grid(img), (32, 32))

    def test_packed_frames_touching_edges(self):
        img = _sheet(5, 2, 24, (0, 4, 19, 22))      # sprites touch the left edge of their cell
        self.assertEqual(sheets.detect_grid(img)[0], 24)

    def test_strip_set_common_width(self):
        # narrow figures centred in 96 px frames: one strip alone also fits 32; the set decides 96
        strips = [_sheet(n, 1, 96, (36, 16, 60, 63)).crop((0, 0, n * 96, 64)) for n in (8, 10, 13, 5)]
        self.assertEqual(sheets.common_strip_width(strips), 96)

    def test_objects(self):
        img = Image.new("RGBA", (64, 40), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([2, 2, 10, 12], fill=(1, 2, 3, 255))
        d.rectangle([20, 5, 40, 30], fill=(1, 2, 3, 255))
        d.rectangle([50, 30, 60, 38], fill=(1, 2, 3, 255))
        self.assertEqual(sheets.find_objects(img), [(2, 2, 11, 13), (20, 5, 41, 31), (50, 30, 61, 39)])


class ScaleTest(unittest.TestCase):
    def test_box_third_hard_alpha_deterministic(self):
        img = _sheet(2, 1, 96, (10, 10, 85, 80))
        a = sheets.scale_sheet(img, 96, 96, 1.0 / 3.0, "box")
        b = sheets.scale_sheet(img, 96, 96, 1.0 / 3.0, "box")
        self.assertEqual(a.size, (64, 32))
        self.assertEqual(a.tobytes(), b.tobytes())
        self.assertTrue(set(a.getchannel("A").getdata()) <= {0, 255})

    def test_nearest_double_keeps_pixels(self):
        img = _sheet(1, 1, 16, (2, 2, 9, 9))
        big = sheets.scale(img, 2.0)
        self.assertEqual(big.size, (32, 32))
        self.assertEqual(big.getpixel((4, 4)), img.getpixel((2, 2)))


class RepoTest(unittest.TestCase):
    def test_check_assets_passes(self):
        r = subprocess.run([sys.executable, str(REPO / "tools" / "assets" / "check_assets.py")], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_registry_up_to_date(self):
        r = subprocess.run([sys.executable, str(REPO / "tools" / "assets" / "scan_packs.py"), "--check"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_skill_installed(self):
        skill = (REPO / ".claude" / "skills" / "asset-integration-pipeline" / "SKILL.md").read_text()
        self.assertTrue(skill.startswith("---\nname: asset-integration-pipeline\ndescription: "))
        self.assertIn("asset-integration-pipeline", (REPO / "CLAUDE.md").read_text())


if __name__ == "__main__":
    unittest.main()
