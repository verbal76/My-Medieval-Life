"""Tests for the requirements register, its validator and its loss detection (tools/check_requirements.py;
owner directives 2026-10-19 and 2026-10-23, REQ-CTRL-01).

The real register is never edited: every failure case runs on an in-memory copy.
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
import requirements_report as rr  # noqa: E402

REGISTER = cr.load((REPO / "docs" / "requirements" / "requirements.json").read_text())


def _open_approved(d):
    return next(r for r in d["requirements"] if r["kind"] == "approved" and r.get("completion") == "OPEN"
                and r.get("approval_status") == "OWNER APPROVED" and r.get("implementation_status") == "NOT STARTED")


def _by(d, rid):
    return next(r for r in d["requirements"] if r["id"] == rid)


def _errs(d):
    return cr.validate(d, check_docs=False)


class RegisterTest(unittest.TestCase):
    def test_register_is_valid(self):
        self.assertEqual(cr.validate(REGISTER), [])

    def test_generated_files_are_up_to_date(self):
        r = subprocess.run([sys.executable, str(REPO / "tools" / "check_requirements.py")], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        for path, text in cr.outputs(REGISTER):
            self.assertEqual(path.read_text(), text, "%s is reproducible from the register" % path)

    def test_every_reconciled_record_is_accounted_for(self):
        """REQ-CTRL-01: every id in every original copy maps to a canonical record or an alias."""
        led = json.loads((REPO / "docs" / "requirements" / "reconciliation_2026-10-23.json").read_text())
        ids = {r["id"] for r in REGISTER["requirements"]}
        aliases = {a for r in REGISTER["requirements"] for a in r.get("aliases") or []}
        for x in led["entries"]:
            self.assertIn(x["canonical_id"], ids, x)
            self.assertTrue(x["id"] in ids or x["id"] in aliases, x)

    def test_dimensions_are_separate_and_known(self):
        for r in REGISTER["requirements"]:
            self.assertNotIn("status", r, r["id"])
            if r["kind"] == "decision":
                self.assertIn(r["disposition"], cr.DISPOSITION)
            else:
                self.assertIn(r["implementation_status"], cr.IMPLEMENTATION)
                self.assertIn(r["verification_status"], cr.VERIFICATION)


class LossDetectionTest(unittest.TestCase):
    def test_deleted_record_is_detected(self):
        new = copy.deepcopy(REGISTER)
        gone = _open_approved(new)
        new["requirements"].remove(gone)
        self.assertTrue(any(gone["id"] in e and "disappeared" in e for e in cr.compare(REGISTER, new)))

    def test_status_change_without_history_is_detected(self):
        new = copy.deepcopy(REGISTER)
        r = _by(new, _open_approved(new)["id"])
        r["implementation_status"] = "READY"
        self.assertTrue(any(r["id"] in e and "no new history" in e for e in cr.compare(REGISTER, new)))
        r["history"].append({"date": "2026-10-23", "change": "ready", "why": "test"})
        self.assertEqual(cr.compare(REGISTER, new), [])

    def test_removed_history_is_detected(self):
        new = copy.deepcopy(REGISTER)
        r = next(x for x in new["requirements"] if len(x["history"]) > 1)
        r["history"].pop()
        self.assertTrue(any(r["id"] in e and "removed" in e for e in cr.compare(REGISTER, new)))

    def test_a_v1_register_is_read_through_the_mapping(self):
        old = {"format": "mml-requirements/1", "requirements": [
            {"id": "ZZ-001", "kind": "approved", "status": "IMPLEMENTED — TESTING REQUIRED", "title": "t", "source": "s",
             "approval": "a", "acceptance": ["c"], "history": [{"date": "d", "change": "c", "why": "w"}], "target_build": "17",
             "commits": ["abc"], "tests": "x"}]}
        d = cr.load(json.dumps(old))
        r = d["requirements"][0]
        self.assertEqual((r["implementation_status"], r["verification_status"], r["completion"]),
                         ("INTEGRATED", "TARGETED TESTS PASSED", "OPEN"))
        self.assertEqual(r["migrated_from_status"], "IMPLEMENTED — TESTING REQUIRED")

    def test_moved_register_is_found_through_previous_paths(self):
        d = copy.deepcopy(REGISTER)
        d["previous_paths"] = ["docs/requirements/requirements.json"]
        self.assertIsNotNone(cr.at_ref("HEAD", d))


class ValidationTest(unittest.TestCase):
    def test_duplicate_ids_aliases_and_dangling_references(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        new["requirements"].append(copy.deepcopy(r))
        self.assertTrue(any("duplicate id" in e for e in _errs(new)))
        new = copy.deepcopy(REGISTER)
        _open_approved(new)["depends_on"] = ["NO-SUCH-1"]
        _open_approved(new)["decisions"] = ["NO-SUCH-2"]
        errs = _errs(new)
        self.assertTrue(any("NO-SUCH-1" in e for e in errs) and any("NO-SUCH-2" in e for e in errs))
        new = copy.deepcopy(REGISTER)
        a, b = [x for x in new["requirements"] if x["kind"] == "approved"][:2]
        a["aliases"], b["aliases"] = ["ZZ-ALIAS"], ["ZZ-ALIAS"]
        self.assertTrue(any("conflicting canonical records" in e for e in _errs(new)))
        b["aliases"] = [a["id"]]
        self.assertTrue(any("itself a record's id" in e for e in _errs(new)))

    def test_invalid_values_and_builds(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["implementation_status"], r["target_build"] = "DONE", "99"
        errs = _errs(new)
        self.assertTrue(any("implementation_status" in e for e in errs) and any("target_build" in e for e in errs))

    def test_contradictory_and_unsupported_states_are_rejected(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["completion"] = "COMPLETE"
        self.assertTrue(any("COMPLETE needs implementation INTEGRATED" in e for e in _errs(new)))
        r["completion"], r["implementation_status"] = "OPEN", "INTEGRATED"
        r.pop("integrated_in", None); r.pop("commits", None); r.pop("legacy_evidence", None)
        self.assertTrue(any("without integration evidence" in e for e in _errs(new)))
        r["implementation_status"], r["verification_status"], r["tests"] = "NOT STARTED", "TARGETED TESTS PASSED", ""
        self.assertTrue(any("without test evidence" in e for e in _errs(new)))
        r["verification_status"], r["tests"] = "OWNER PLAYTESTED", "x"
        self.assertTrue(any("without a gameplay or playtest record" in e for e in _errs(new)))
        r["verification_status"] = "NOT TESTED"
        r["implementation_status"] = "IN DEVELOPMENT"
        self.assertTrue(any("needs assigned_worker and branch" in e for e in _errs(new)))
        p = next(x for x in new["requirements"] if x["kind"] == "proposal")
        p["release_status"] = "RELEASE READY"
        self.assertTrue(any(p["id"] in e and "not owner approved" in e for e in _errs(new)))

    def test_approved_work_needs_acceptance_and_approval(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["acceptance"], r["approval"] = [], ""
        errs = _errs(new)
        self.assertTrue(any("acceptance criteria" in e for e in errs) and any("approval evidence" in e for e in errs))

    def test_unauthorized_builds_cannot_hold_work(self):
        new = copy.deepcopy(REGISTER)
        r = _open_approved(new)
        r["target_build"], r["implementation_status"] = "20", "INTEGRATED"
        r["commits"] = ["abc"]
        self.assertTrue(any("not authorized" in e for e in _errs(new)))

    def test_open_decision_is_not_silently_answered(self):
        new = copy.deepcopy(REGISTER)
        q = next(x for x in new["requirements"] if x["kind"] == "decision" and x["disposition"] == "OPEN")
        q["disposition"] = "APPROVED"
        q["owner_answer"] = q["owner_wording"] = None
        self.assertTrue(any(q["id"] in e and "owner's words" in e for e in _errs(new)))
        self.assertTrue(any(q["id"] in e for e in cr.compare(REGISTER, new)))

    def test_x19_decay_stays_provisional(self):
        self.assertEqual(_by(REGISTER, "X19-DECAY")["disposition"], "PROVISIONAL")
        self.assertEqual(_by(REGISTER, "OD-21")["disposition"], "APPROVED")

    def test_memory_files_cover_work_in_development(self):
        self.assertTrue(cr.MEMORY.exists() and cr.STATE.exists())
        self.assertEqual(cr.memory_errors(REGISTER), [])
        new = copy.deepcopy(REGISTER)
        fake = copy.deepcopy(_open_approved(new))
        fake.update({"id": "ZZ-999", "implementation_status": "IN DEVELOPMENT", "assigned_worker": "w", "branch": "b"})
        new["requirements"].append(fake)
        self.assertTrue(any("ZZ-999" in e for e in cr.memory_errors(new)))

    def test_baseline_entries_cannot_vanish_or_change_silently(self):
        bp = REPO / "docs" / "requirements" / "baseline_2026-10-20.json"
        b = json.loads(bp.read_text())
        self.assertEqual(cr.baseline_errors(REGISTER, b), [])
        new = copy.deepcopy(REGISTER)
        gone = sorted(b["open"])[0]
        new["requirements"] = [r for r in new["requirements"] if r["id"] != gone]
        self.assertTrue(any(gone in e and "missing" in e for e in cr.baseline_errors(new, b)))
        new = copy.deepcopy(REGISTER)
        r = _by(new, sorted(b["open"])[1])
        del r["history"][b["open"][r["id"]]["history"]:]
        r["target_build"] = "20+" if r.get("target_build") != "20+" else "16"
        self.assertTrue(any(r["id"] in e and "no history" in e for e in cr.baseline_errors(new, b)))

    def test_document_references_in_any_field_must_exist(self):
        new = copy.deepcopy(REGISTER)
        _open_approved(new)["implementation"] = "see docs/NO_SUCH_FILE.md"
        self.assertTrue(any("NO_SUCH_FILE" in e for e in cr.validate(new)))

    def test_claude_md_starts_sessions_from_the_memory(self):
        text = (REPO / "CLAUDE.md").read_text()
        head = text[:text.index("## 1.")]
        self.assertIn("Session start", head)
        self.assertIn("docs/PROJECT_MEMORY.md", head)
        self.assertIn("docs/CURRENT_DEVELOPMENT_STATE.md", head)
        self.assertIn("docs/requirements/views/", head)
        self.assertEqual(sum(1 for n in range(1, 9) if ("\n%d. **" % n) in head), 8, "the eight startup steps")


class ReportTest(unittest.TestCase):
    def test_proposals_umbrellas_and_superseded_are_not_counted(self):
        for b in rr.BUILDS:
            for r in rr.scoped(REGISTER, b):
                self.assertEqual(r["kind"], "approved")
                self.assertFalse(r.get("umbrella"))
                self.assertIn(r["approval_status"], ("OWNER APPROVED", "OWNER DECISION REQUIRED"))

    def test_builds_20_and_21_are_marked_not_authorized(self):
        for b in ("20", "21"):
            self.assertIn("NOT AUTHORIZED", rr.build_view(REGISTER, b))


if __name__ == "__main__":
    unittest.main()
