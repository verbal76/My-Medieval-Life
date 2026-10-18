"""Tests for the system interaction manifest and its validator."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import check_interactions as ci  # noqa: E402

GOOD = """# t

## Systems

- **Alpha** — a
- **Beta** — b

## Interactions

### INT-001 · First
- **Trigger:** x
- **Source:** `code.gd::run`
- **Affects:** Alpha
- **Expected:** y
- **Tests:** `code.gd`

## Reverse dependency index

%s
""" % "\n".join([ci.INDEX_START, "", "| System | Interactions |", "|---|---|",
                 "| Alpha | INT-001 |", "| Beta | none |", "", ci.INDEX_END])


class ManifestTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "code.gd").write_text("func run() -> void:\n\tpass\n")

    def tearDown(self):
        self.tmp.cleanup()

    def test_the_repository_manifest_is_valid(self):
        self.assertEqual(ci.problems(ci.DOC.read_text()), [])

    def test_a_valid_sample_passes(self):
        self.assertEqual(ci.problems(GOOD, self.root), [])

    def test_duplicate_and_decreasing_ids(self):
        dup = GOOD.replace("## Reverse", "### INT-001 · Again\n- **Trigger:** x\n\n## Reverse")
        self.assertTrue(any("duplicate id" in p for p in ci.problems(dup, self.root)))
        self.assertTrue(any("missing Source" in p for p in ci.problems(dup, self.root)))

    def test_missing_file_function_and_system(self):
        bad = GOOD.replace("`code.gd::run`", "`code.gd::walk`, `gone.gd`").replace("Affects:** Alpha", "Affects:** Gamma")
        found = ci.problems(bad, self.root)
        self.assertTrue(any("no func walk" in p for p in found))
        self.assertTrue(any("not found: gone.gd" in p for p in found))
        self.assertTrue(any("unknown system 'Gamma'" in p for p in found))

    def test_stale_index_is_reported_and_rewritten(self):
        stale = GOOD.replace("| Beta | none |", "| Beta | INT-001 |")
        self.assertTrue(any("out of date" in p for p in ci.problems(stale, self.root)))
        self.assertEqual(ci.write_index(stale), GOOD)


if __name__ == "__main__":
    unittest.main()
