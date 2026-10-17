"""Tests for the Morris world registries: determinism, id resolution and merge sanity."""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools" / "lore"))

import build_registries as br  # noqa: E402


class RegistryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.chapters = br.load_chapters()
        cls.merges = json.loads(br.MERGES.read_text())
        cls.old = json.loads((br.OUT / "ids.json").read_text())["ids"]
        cls.reg, cls.ids, _ = br.build(cls.chapters, cls.merges, cls.old)

    def test_build_is_deterministic(self):
        reg2, ids2, _ = br.build(self.chapters, self.merges, self.old)
        self.assertEqual(json.dumps(self.reg, sort_keys=True), json.dumps(reg2, sort_keys=True))
        self.assertEqual(self.ids, ids2)

    def test_committed_registries_are_current(self):
        for sec, rows in self.reg.items():
            saved = json.loads((br.OUT / f"{sec}.json").read_text())["records"]
            self.assertEqual(saved, json.loads(json.dumps(rows)), sec)

    def test_issued_ids_are_kept_and_unique(self):
        for name, i in self.old.items():
            self.assertEqual(self.ids[name], i)
        ent_ids = [e["id"] for e in self.reg["entities"]]
        self.assertEqual(len(ent_ids), len(set(ent_ids)))

    def test_every_reference_resolves(self):
        known = {e["id"] for e in self.reg["entities"]}
        for sec, rows in self.reg.items():
            for r in rows:
                for k, v in r.items():
                    if k.endswith("_id"):
                        self.assertIn(v, known, (sec, r["id"], k))
                    elif k.endswith("_ids"):
                        for x in v:
                            self.assertIn(x, known, (sec, r["id"], k))

    def test_merge_sources_exist_and_targets_survive(self):
        names = {e["name"] for e in self.reg["entities"]}
        for src, m in self.merges["merge"].items():
            self.assertNotIn(src, names, src)
            self.assertIn(m["into"], names, src)

    def test_game_ideas_are_never_canon(self):
        for o in self.reg["opportunities"]:
            self.assertEqual(o["classification"], "GAME EXPANSION")
        for f in self.reg["facts"]:
            self.assertIn(f["classification"], {"CANON", "CANON-INFERRED"})


if __name__ == "__main__":
    unittest.main()
