"""Tests for the resource registry (game/data/resources.json) and its validator."""
import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import check_resources as cr  # noqa: E402


class ResourceRegistryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ctx = cr.load()

    def mutated(self, change):
        ctx = dict(self.ctx)
        ctx["res"] = copy.deepcopy(self.ctx["res"])
        change(ctx["res"])
        return cr.problems(ctx)

    def test_the_repository_registry_is_valid_and_its_documents_current(self):
        self.assertEqual(cr.problems(self.ctx), [])
        for path, text in cr.documents(self.ctx).items():
            self.assertEqual(path.read_text(), text, "%s is stale: run tools/check_resources.py --write" % path.name)

    def test_generation_is_deterministic(self):
        self.assertEqual(cr.documents(self.ctx), cr.documents(cr.load()))

    def test_every_harvestable_kind_needs_a_node(self):
        found = self.mutated(lambda r: r["nodes"].pop("copper_seam"))
        self.assertTrue(any("deposit ore 'copper_ore'" in p for p in found))
        found = self.mutated(lambda r: r["nodes"].pop("wild_rabbit"))
        self.assertTrue(any("species 'rabbit' has no node" in p for p in found))
        found = self.mutated(lambda r: r["nodes"].pop("tree"))
        self.assertTrue(any("trees but no tree node" in p for p in found))

    def test_duplicate_ids_are_refused(self):
        with self.assertRaises(ValueError):
            json.loads('{"nodes": {"tree": {}, "tree": {}}}', object_pairs_hook=cr._unique_pairs)

    def test_bad_node_fields(self):
        def bad(r):
            n = r["nodes"]["iron_seam"]
            n["yields"] = {"mithril": 1}
            n["tool"] = "spade"
            n["depletion"] = "sometimes"
            n["minutes_key"] = "dig_minutes"
            n["gather"] = False
            n["sources"] = ["game/scripts/core/world.gd::dig_unit"]
            del n["owner"]
        found = self.mutated(bad)
        for want in ("unknown item 'mithril'", "tool 'spade'", "depletion 'sometimes'", "minutes_key 'dig_minutes'",
                     "needs gather true", "has no func dig_unit", "missing owner"):
            self.assertTrue(any(want in p for p in found), want)

    def test_findings_must_be_recorded_and_exceptions_must_not_be_stale(self):
        found = self.mutated(lambda r: r.__setitem__("exceptions", [e for e in r["exceptions"] if e["item"] != "spice"]))
        self.assertTrue(any("finding not recorded: spice" in p for p in found))
        found = self.mutated(lambda r: r["exceptions"].append({"item": "log", "finding": "no_source", "status": "implemented", "reason": "x"}))
        self.assertTrue(any("stale exception: log" in p for p in found))

    def test_code_notes_must_match_the_code(self):
        found = self.mutated(lambda r: r["exports"]["smith_caps"].pop("pickaxe"))
        self.assertTrue(any("smith_caps" in p for p in found))
        found = self.mutated(lambda r: r["materials"].pop("plank"))
        self.assertTrue(any("ManorWork.MATERIALS" in p for p in found))
        found = self.mutated(lambda r: r["code_sources"][0]["items"].remove("axe"))
        self.assertTrue(any("population.gd::_equip" in p for p in found))

    def test_the_findings_the_owner_asked_for(self):
        s = cr.summary(self.ctx)
        self.assertEqual(s["no_source"], [])                # Build 13: the gold seam gives gold ore a source; B14: apple trees give apples
        self.assertEqual(s["missing_recipes"], [])          # so smelt_gold and forge_gold_ring can be made
        self.assertEqual(s["finite"], ["boulder", "coal_seam", "copper_seam", "gold_seam", "horse_pen", "iron_seam", "open_pit", "prospect_clue", "stone_seam", "tunnel_rock"])
        # Build 13: scarce by design; the caravan brings no gold. MIN-C: a clue's samples are finite by design (new
        # ground to read is MIN-D's). MIN-E: a pit's earth is its finite ground; nothing brings topsoil, dirt or spoil
        self.assertEqual(s["finite_no_replacement"], ["gold_seam", "horse_pen", "open_pit", "prospect_clue", "tunnel_rock"])
        self.assertIn(("log", "plank", "pickaxe"), s["chains"])
        # PL2-013: the home food table makes bread (knead_flatbread, 3 wheat), so bread is a chain now
        self.assertIn(("wheat", "bread"), s["chains"])
        self.assertEqual(s["not_gather"], ["chicken_pen", "cow_pen", "horse_pen", "pig_pen", "player_field", "player_pen", "sheep_pen"])   # PL2-015: the player's field and pens are worked by Use, not Gather mode

    def test_both_directions_agree_with_recipes(self):
        for r, rec in self.ctx["recipes"].items():
            for i in rec["in"]:
                self.assertIn(("recipe", r), [(k, x) for k, x, *_ in cr.uses_of(self.ctx, i)])
            for o in rec["out"]:
                self.assertIn(("recipe", r), [(k, x) for k, x, *_ in cr.sources_of(self.ctx, o)])
        self.assertEqual(cr.raw_needs(self.ctx, "pickaxe"), {"iron_ore": 4.0, "coal": 2.0, "log": 0.5})

    def test_the_journal_page_reads_the_registry(self):
        ui = (cr.ROOT / "game" / "scripts" / "ui" / "game_ui.gd").read_text()
        res = self.ctx["res"]
        self.assertEqual(cr.journal_problems(res, ui), [])
        self.assertIn("func show_resources(", ui)
        # a node id, a node's name or a product written into the page's code is refused
        for literal in ['"tree"', '"Iron seam"', '"Gives: Log"']:
            bad = ui.replace("func _res_list(lines: VBoxContainer) -> void:\n",
                             "func _res_list(lines: VBoxContainer) -> void:\n\tprint(%s)\n" % literal, 1)
            self.assertNotEqual(bad, ui)
            self.assertTrue(cr.journal_problems(res, bad), literal)
        bad = ui.replace('const GATHER_KEYS := "', 'const GATHER_KEYS := "Wheat field: ', 1)
        self.assertTrue(cr.journal_problems(res, bad))
        # ...and a page that does not read ResourceNodes is refused
        self.assertTrue(cr.journal_problems(res, ui.replace("ResourceNodes.", "Other.")))


if __name__ == "__main__":
    unittest.main()
