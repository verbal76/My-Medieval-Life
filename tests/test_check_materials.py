"""Tests for the material interdependency report (tools/check_materials.py, WDR-007-C).

Positive and negative compliance fixtures (World Design Rule 007): a small synthetic economy that
meets Rules 001 and 002, then one defect at a time (a material with only two uses, a material one
profession consumes, a profession supplying nobody, an orphaned recipe, a broken reference, a stale
exception), each of which the report must detect; and the committed report must be what --write
generates from the real game data.
"""
import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import check_materials as cm  # noqa: E402


def res(**kw):
    return dict({"type": "resource"}, **kw)


# Ore is mined, smelted into bars at the forge; bars and planks become tools, nails and a cart;
# the woodcutter's logs are sawn into planks; the miner needs the smith's pickaxe.
FIXTURE = {
    "items": {"ore": res(), "bar": res(), "log": res(), "plank": res(), "nails": res(),
              "pickaxe": {"type": "tool"}, "axe": {"type": "tool"}, "cart": res(cart=True),
              "chair": {"type": "furniture"}},
    "recipes": {
        "smelt": {"station": "forge", "in": {"ore": 2}, "out": {"bar": 1}},
        "saw": {"station": "sawhorse", "in": {"log": 1}, "out": {"plank": 2}},
        "pickaxe": {"station": "anvil", "in": {"bar": 2, "plank": 1, "nails": 1}, "out": {"pickaxe": 1}},
        "axe": {"station": "anvil", "in": {"bar": 2, "plank": 1}, "out": {"axe": 1}},
        "nails": {"station": "anvil", "in": {"bar": 1}, "out": {"nails": 10}},
        "cart": {"station": "workbench", "in": {"plank": 4, "bar": 1, "nails": 4}, "out": {"cart": 1}},
        "chair": {"station": "workbench", "in": {"plank": 2, "nails": 2}, "out": {"chair": 1}},
    },
    "stations": ["anvil", "forge", "sawhorse", "workbench"],
    "jobs": ["carpenter", "miner", "smith", "woodcutter"],
    "crafters": {"smelt": ["smith"], "pickaxe": ["smith"], "axe": ["smith"], "nails": ["smith"],
                 "saw": ["carpenter"], "cart": ["carpenter"], "chair": ["carpenter"]},
    "household": [],
    "gathering": {"miner": ["ore"], "woodcutter": ["log"]},
    "needs": {"miner": {"pickaxe": "keeps"}, "woodcutter": {"axe": "keeps"}},
    "resale": [],
    "construction": {"house": {"house": {"plank": 10, "nails": 5}}},
    "end_uses": {"pickaxe": ["equipment"], "axe": ["equipment"], "cart": ["cart"], "chair": ["furniture"]},
    "code_refs": [{"ref": "npc_brain.gd::_smith", "ok": True}],
    "exceptions_format": cm.EXC_FORMAT,
    "exceptions": [
        {"material": "ore", "finding": "few_uses", "reason": "feedstock: smelted into bars", "rule": "WDR-001"},
        {"material": "ore", "finding": "few_professions", "reason": "feedstock: smelted into bars", "rule": "WDR-001"},
        {"material": "log", "finding": "few_uses", "reason": "feedstock: sawn into planks", "rule": "WDR-001"},
        {"material": "log", "finding": "few_professions", "reason": "feedstock: sawn into planks", "rule": "WDR-001"},
    ],
}


class MaterialFixtureTest(unittest.TestCase):
    def report(self, change=None):
        data = copy.deepcopy(FIXTURE)
        if change:
            change(data)
        return cm.build_report(data)

    def findings(self, report):
        return {(v["kind"], v["subject"], v["finding"]) for v in report["open"]}

    def test_positive_fixture_passes(self):
        r = self.report()
        self.assertEqual(r["open"], [])
        self.assertEqual(r["broken"], [])
        self.assertEqual(r["stale"], [])
        self.assertEqual(r["orphans"], {})
        self.assertEqual(cm.errors(r, strict=True), [])
        # bar: pickaxe, axe, nails, cart (4 products) by smith and carpenter
        self.assertEqual(r["materials"]["bar"]["uses"], 4)
        self.assertEqual(r["materials"]["bar"]["professions"], ["carpenter", "smith"])
        # plank: four recipes and a house
        self.assertEqual(r["materials"]["plank"]["construction"], ["house"])
        self.assertEqual(r["materials"]["plank"]["uses"], 5)
        self.assertIn("carpenter", r["professions"]["smith"]["supplies"])
        self.assertIn("miner", r["professions"]["smith"]["supplies"])
        self.assertIn("# Material interdependency report", cm.render(r))

    def test_material_with_only_two_uses_is_flagged(self):
        def two(d):   # nails lose the house and the chair; more recipes, but only two distinct products
            d["construction"] = {}
            del d["recipes"]["chair"]
            del d["crafters"]["chair"]
            d["recipes"]["crate"] = {"station": "workbench", "in": {"nails": 1, "plank": 1}, "out": {"cart": 1}}
            d["recipes"]["box"] = {"station": "anvil", "in": {"nails": 1}, "out": {"pickaxe": 1}}
            d["crafters"]["box"] = ["smith"]
        r = self.report(two)
        self.assertEqual(r["materials"]["nails"]["uses"], 2)   # cart twice counts once (Rule 003), pickaxe once
        self.assertIn(("material", "nails", "few_uses"), self.findings(r))
        self.assertEqual(cm.errors(r), [])                    # a threshold finding is not a hard error...
        self.assertTrue(cm.errors(r, strict=True))            # ...unless strict

    def test_near_duplicate_recipes_count_once(self):
        def dup(d):
            d["construction"] = {}
            del d["recipes"]["chair"]
            del d["crafters"]["chair"]
            d["recipes"]["cart2"] = dict(d["recipes"]["cart"])
            d["crafters"]["cart2"] = ["carpenter"]
        r = self.report(dup)
        self.assertEqual(len(r["materials"]["nails"]["recipes"]), 3)   # pickaxe, cart, cart2
        self.assertEqual(r["materials"]["nails"]["uses"], 2)
        self.assertIn(("material", "nails", "few_uses"), self.findings(r))

    def test_material_one_profession_consumes_is_flagged(self):
        def one(d):
            d["crafters"]["cart"] = ["smith"]
            d["crafters"]["chair"] = []          # the player's alone: no profession
        r = self.report(one)
        self.assertEqual(r["materials"]["nails"]["professions"], ["smith"])
        self.assertIn(("material", "nails", "few_professions"), self.findings(r))

    def test_profession_supplying_nobody_is_flagged(self):
        def nobody(d):
            d["jobs"].append("baker")
            d["items"]["bread"] = {"type": "food", "food": 50}
            d["items"]["flour"] = res()
            d["recipes"]["bake"] = {"station": "oven", "in": {"flour": 1}, "out": {"bread": 1}}
            d["stations"].append("oven")
            d["crafters"]["bake"] = ["baker"]
            d["end_uses"]["bread"] = ["food"]
            d["exceptions"] += [{"material": "flour", "finding": f, "reason": "test", "rule": "WDR-001"}
                                for f in ("few_uses", "few_professions")]
        r = self.report(nobody)
        self.assertIn(("profession", "baker", "supplies_nobody"), self.findings(r))
        self.assertNotIn(("profession", "smith", "supplies_nobody"), self.findings(r))

    def test_orphaned_recipe_is_flagged(self):
        def orphan(d):
            d["items"]["trinket"] = res()
            d["recipes"]["trinket"] = {"station": "anvil", "in": {"bar": 1}, "out": {"trinket": 1}}
            d["crafters"]["trinket"] = ["smith"]
        r = self.report(orphan)
        self.assertIn("trinket", r["orphans"])
        self.assertIn(("recipe", "trinket", "orphan"), self.findings(r))
        # an end good is not an orphan
        self.assertNotIn("pickaxe", r["orphans"])

    def test_broken_references_are_errors(self):
        def broken(d):
            d["recipes"]["smelt"]["in"]["coal"] = 1           # unknown item
            d["recipes"]["saw"]["station"] = "lathe"          # unknown station
            d["crafters"]["weave"] = ["weaver"]               # unknown recipe and job
            d["construction"]["house"]["house"]["glass"] = 4  # unknown item in a construction
            d["code_refs"].append({"ref": "npc_brain.gd::_weaver", "ok": False})
        r = self.report(broken)
        text = "\n".join(r["broken"])
        for want in ["unknown item 'coal'", "unknown station 'lathe'", "unknown recipe 'weave'",
                     "unknown job 'weaver'", "unknown item 'glass'", "cited code not found: npc_brain.gd::_weaver"]:
            self.assertIn(want, text)
        self.assertTrue(cm.errors(r))

    def test_stale_and_invalid_exceptions_are_errors(self):
        def stale(d):
            d["exceptions"].append({"material": "bar", "finding": "few_uses", "reason": "x", "rule": "WDR-001"})
        r = self.report(stale)
        self.assertTrue(any("stale exception: material bar few_uses" in s for s in r["stale"]))
        self.assertTrue(cm.errors(r))

        def invalid(d):
            d["exceptions"].append({"material": "ore", "finding": "too_shiny", "reason": "x", "rule": "WDR-001"})
            d["exceptions"].append({"material": "unobtainium", "finding": "few_uses", "reason": "x", "rule": "WDR-001"})
            d["exceptions"][0]["reason"] = ""
        r = self.report(invalid)
        self.assertTrue(any("unknown finding 'too_shiny'" in s for s in r["stale"]))
        self.assertTrue(any("unknown material 'unobtainium'" in b for b in r["broken"]))
        self.assertTrue(any("needs a reason and a rule" in s for s in r["stale"]))

    def test_undocumented_exception_is_open(self):
        def drop(d):
            d["exceptions"] = d["exceptions"][1:]
        r = self.report(drop)
        self.assertEqual(self.findings(r), {("material", "ore", "few_uses")})


class RealDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = cm.load()
        cls.report = cm.build_report(cls.data)

    def test_real_data_has_no_hard_errors(self):
        self.assertEqual(cm.errors(self.report), [])

    def test_job_code_is_found(self):
        self.assertTrue(all(r["ok"] for r in self.data["code_refs"]), self.data["code_refs"])
        self.assertIn("smith", self.data["crafters"]["smelt_iron"])
        self.assertIn("carpenter", self.data["crafters"]["saw_planks"])
        self.assertIn("saw_planks", self.data["household"])

    def test_committed_report_is_current(self):
        self.assertEqual(cm.DOC.read_text(), cm.render(self.report),
                         "docs/systems/MATERIAL_INTERDEPENDENCY.md is stale: run tools/check_materials.py --write")

    def test_generation_is_deterministic(self):
        self.assertEqual(cm.render(self.report), cm.render(cm.build_report(cm.load())))


if __name__ == "__main__":
    unittest.main()


class EvidencedExceptionTest(unittest.TestCase):
    """B18-DP-15 (owner): a supplies_nobody exception stands only on a functioning cross-profession relationship the
    checker can see; an unsupported one fails, and missing demand never passes by being written down."""

    @classmethod
    def setUpClass(cls):
        cls.data = cm.load()

    def _sage(self, data):
        return next(e for e in data["exceptions"] if e.get("profession") == "sage" and e["finding"] == "supplies_nobody")

    def _stale_for_sage(self, data):
        return [s for s in cm.build_report(data)["stale"] if "sage" in s]

    def test_the_real_sage_exception_is_evidenced(self):
        self.assertEqual(self._stale_for_sage(self.data), [])
        self.assertTrue(cm.errors(cm.build_report(self.data)) == [])

    def test_without_evidence_it_fails(self):
        d = copy.deepcopy(self.data)
        e = self._sage(d)
        e.pop("evidence")
        e.pop("_checked", None)
        self.assertTrue(any("unsupported" in s for s in self._stale_for_sage(d)))

    def test_a_missing_test_or_code_fails(self):
        for part in ("test", "code", "mentions"):
            d = copy.deepcopy(self.data)
            self._sage(d)["_checked"][part] = False
            self.assertTrue(any("unsupported" in s for s in self._stale_for_sage(d)), part)

    def test_goods_the_profession_does_not_make_fail(self):
        d = copy.deepcopy(self.data)
        self._sage(d)["evidence"]["goods"] = ["iron_bar"]
        self.assertTrue(any("unsupported" in s for s in self._stale_for_sage(d)))

    def test_other_findings_are_unchanged(self):
        d = copy.deepcopy(self.data)
        d["exceptions"] = [e for e in d["exceptions"] if e.get("finding") != "supplies_nobody"]
        r = cm.build_report(d)
        self.assertIn(("profession", "sage", "supplies_nobody"), {(v["kind"], v["subject"], v["finding"]) for v in r["open"]})
