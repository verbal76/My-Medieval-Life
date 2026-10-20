"""Tests for the requirements register and its loss detection (tools/check_requirements.py).

The real register is never edited: the deletion and premature-closure cases run on in-memory copies.
"""
import copy
import json
import subprocess
import sys
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import check_requirements as cr  # noqa: E402

REGISTER = json.loads((REPO / "docs" / "requirements" / "requirements.json").read_text())


def _open_approved(d):
    return next(r for r in d["requirements"] if r["kind"] == "approved" and r["status"] not in cr.CLOSED)


class RegisterTest(unittest.TestCase):
    def test_register_is_valid(self):
        self.assertEqual(cr.validate(REGISTER), [])

    def test_ledger_is_generated_from_register(self):
        r = subprocess.run([sys.executable, str(REPO / "tools" / "check_requirements.py")], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_counts_reconcile(self):
        c = cr.counts(REGISTER)
        self.assertEqual(sum(c.values()), sum(1 for r in REGISTER["requirements"] if r["kind"] == "approved"))
        self.assertTrue(set(c) <= set(cr.LIFECYCLE))


class LossDetectionTest(unittest.TestCase):
    def test_deleted_requirement_is_detected(self):
        new = copy.deepcopy(REGISTER)
        gone = _open_approved(new)
        new["requirements"] = [r for r in new["requirements"] if r["id"] != gone["id"]]
        errors = cr.compare(REGISTER, new)
        self.assertTrue(any(gone["id"] in e and "disappeared" in e for e in errors), errors)

    def test_closing_without_history_is_detected(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["status"] = "COMPLETE AND VERIFIED"
        self.assertTrue(any(r["id"] in e and "history" in e for e in cr.compare(REGISTER, new)))

    def test_closing_with_history_is_accepted(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["status"] = "SUPERSEDED"
        r["superseded_by"] = next(x["id"] for x in new["requirements"] if x["id"] != r["id"])
        r["history"].append({"date": "2026-10-19", "change": "superseded", "why": "test"})
        self.assertEqual(cr.compare(REGISTER, new), [])
        self.assertEqual(cr.validate(new, check_docs=False), [])

    def test_removed_history_is_detected(self):
        new = copy.deepcopy(REGISTER)
        r = new["requirements"][0]
        r["history"] = []
        self.assertTrue(any("history" in e for e in cr.compare(REGISTER, new)))

    def test_bad_closures_are_rejected(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["status"] = "SUPERSEDED"                      # no successor named
        self.assertTrue(any(r["id"] in e and "superseded_by" in e for e in cr.validate(new, check_docs=False)))
        r["status"] = "CANCELED BY OWNER"               # no owner cancellation cited
        r["superseded_by"] = None
        self.assertTrue(any(r["id"] in e and "canceled" in e.lower() for e in cr.validate(new, check_docs=False)))
        r["status"] = "COMPLETE AND VERIFIED"
        r["implementation"], r["tests"], r["commits"], r["playtest"] = "", "", [], []
        self.assertTrue(any(r["id"] in e and "evidence" in e for e in cr.validate(new, check_docs=False)))

    def test_duplicate_and_dangling_ids_are_rejected(self):
        new = copy.deepcopy(REGISTER)
        new["requirements"].append(copy.deepcopy(new["requirements"][0]))
        new["requirements"][1]["depends_on"] = ["NOPE-999"]
        errors = cr.validate(new, check_docs=False)
        self.assertTrue(any("duplicate" in e for e in errors) and any("NOPE-999" in e for e in errors))

    def test_moved_register_is_found_through_previous_paths(self):
        d = {"format": "mml-requirements/1", "previous_paths": ["docs/requirements/requirements.json"], "requirements": []}
        old = cr.at_ref("HEAD", d)
        self.assertTrue(old is None or old["format"] == "mml-requirements/1")


class RoadmapAndMemoryTest(unittest.TestCase):
    """MEM-01 (owner 2026-10-20): the safeguards that keep the roadmap and the project memory from drifting."""

    def _by(self, d, rid):
        return next(r for r in d["requirements"] if r["id"] == rid)

    def test_open_entry_needs_a_target_build(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["target_build"] = "21"
        self.assertTrue(any(r["id"] in e and "roadmap target" in e for e in cr.validate(new, check_docs=False)))

    def test_open_decision_is_not_silently_resolved(self):
        new = copy.deepcopy(REGISTER)
        q = self._by(new, "SJD-Q01")
        q["status"] = "APPROVED — NOT STARTED"
        q["history"].append({"date": "2026-10-20", "change": "decided", "why": "test"})
        self.assertTrue(any("SJD-Q01" in e and "owner_answer" in e for e in cr.validate(new, check_docs=False)))
        q["status"], q["kind"] = "BLOCKED", "approved"
        q["approval"] = "agent"
        self.assertTrue(any("SJD-Q01" in e and "owner decision became" in e for e in cr.compare(REGISTER, new)))

    def test_moving_build_without_history_is_detected(self):
        new = copy.deepcopy(REGISTER)
        r = next(x for x in new["requirements"] if x.get("target_build") == "17")
        r["target_build"] = "16"
        self.assertTrue(any(r["id"] in e and "moved from build" in e for e in cr.compare(REGISTER, new)))

    def test_roadmap_anchors_and_expansion_specs_are_required(self):
        new = copy.deepcopy(REGISTER)
        new["requirements"] = [r for r in new["requirements"] if r["id"] != "EXP-B"]
        self._by(new, "EXP-A")["source"] = "chat"
        errors = cr.validate(new, check_docs=False)
        self.assertTrue(any(e.startswith("EXP-B") for e in errors) and any(e.startswith("EXP-A") for e in errors), errors)
        for a in cr.ANCHORS:
            if a.startswith("EXP-"):
                src = self._by(REGISTER, a)["source"]
                self.assertTrue(all((REPO / m).exists() for m in cr.DOC_RE.findall(src)), a)

    def test_memory_files_cover_active_work(self):
        self.assertTrue(cr.MEMORY.exists() and cr.STATE.exists())
        self.assertEqual(cr.memory_errors(REGISTER), [])
        new = copy.deepcopy(REGISTER)
        fake = copy.deepcopy(_open_approved(new))
        fake["id"], fake["status"] = "ZZ-999", "ACTIVE DEVELOPMENT"
        new["requirements"].append(fake)
        self.assertTrue(any("ZZ-999" in e for e in cr.memory_errors(new)))

    def test_claude_md_starts_sessions_from_the_memory(self):
        text = (REPO / "CLAUDE.md").read_text()
        head = text[:text.index("## 1.")]
        self.assertIn("Session start", head)
        self.assertIn("docs/PROJECT_MEMORY.md", head)
        self.assertIn("docs/CURRENT_DEVELOPMENT_STATE.md", head)


if __name__ == "__main__":
    unittest.main()
