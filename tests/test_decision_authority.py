"""Tests for the decision authority and supersession safeguard (tools/decision_authority.py; owner directive HAG-AUTH-01,
docs/directives/2026-11-09_decision_authority_supersession_safeguard.md). Documents only: no game runs.

The real register is never edited: failure cases run on in-memory copies, and the document checks on a temporary directory.
"""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import decision_authority as da  # noqa: E402

REGISTER = json.loads((REPO / "docs" / "requirements" / "requirements.json").read_text())


def _by(d, rid):
    return next(r for r in d["requirements"] if r["id"] == rid)


def _active_decision(d, skip=()):
    return next(r for r in d["requirements"] if r["kind"] == "decision" and da.lifecycle(r) == "ACTIVE" and r["id"] not in skip
                and not r.get("supersedes"))


class LifecycleTest(unittest.TestCase):
    def test_real_register_has_no_authority_problems(self):
        self.assertEqual(da.record_errors(REGISTER), [])
        self.assertEqual(da.document_errors(REGISTER), [])

    def test_every_record_has_one_of_the_six_lifecycles(self):
        for r in REGISTER["requirements"]:
            self.assertIn(r.get("lifecycle"), da.LIFECYCLES, r["id"])

    def test_derivation(self):
        self.assertEqual(da.lifecycle({"kind": "decision", "disposition": "OPEN"}), "UNDER REVIEW")
        self.assertEqual(da.lifecycle({"kind": "decision", "disposition": "APPROVED"}), "ACTIVE")
        self.assertEqual(da.lifecycle({"kind": "decision", "disposition": "SUPERSEDED", "superseded_by": "X-1"}), "SUPERSEDED")
        self.assertEqual(da.lifecycle({"kind": "approved", "approval_status": "OWNER APPROVED", "completion": "COMPLETE"}), "COMPLETED")
        self.assertEqual(da.lifecycle({"kind": "approved", "approval_status": "OWNER APPROVED", "completion": "OPEN"}), "ACTIVE")
        self.assertEqual(da.lifecycle({"kind": "proposal", "approval_status": "REJECTED"}), "REJECTED")
        self.assertEqual(da.lifecycle({"kind": "approved", "approval_status": "DEFERRED"}), "DEFERRED")
        # a rule or decision stays ACTIVE even when its work is done (directive point 6)
        self.assertEqual(da.lifecycle({"kind": "rule", "approval_status": "OWNER APPROVED", "completion": "COMPLETE"}), "ACTIVE")

    def test_lifecycle_out_of_step_is_detected(self):
        d = copy.deepcopy(REGISTER)
        r = _active_decision(d)
        r["lifecycle"] = "COMPLETED"
        self.assertTrue(any(r["id"] in e and "disagrees" in e for e in da.record_errors(d)))
        del r["lifecycle"]
        self.assertTrue(any(r["id"] in e and "missing" in e for e in da.record_errors(d)))


class SupersessionTest(unittest.TestCase):
    def test_one_way_links_are_detected(self):
        d = copy.deepcopy(REGISTER)
        old = next(r for r in d["requirements"] if r.get("superseded_by"))
        new = _by(d, old["superseded_by"])
        new["supersedes"] = [x for x in da.as_list(new.get("supersedes")) if x != old["id"]]
        self.assertTrue(any("one-way link" in e for e in da.record_errors(d)))
        d = copy.deepcopy(REGISTER)
        a, b = _active_decision(d), None
        b = _active_decision(d, skip=(a["id"],))
        b["supersedes"] = [a["id"]]                      # claims to replace a decision still marked ACTIVE
        self.assertTrue(any("is not marked superseded by it" in e for e in da.record_errors(d)))

    def test_loops_and_dead_ends_are_detected(self):
        d = copy.deepcopy(REGISTER)
        a = _active_decision(d)
        b = _active_decision(d, skip=(a["id"],))
        for x, y in ((a, b), (b, a)):
            da.link_supersession({r["id"]: r for r in d["requirements"]}, x["id"], y["id"], "2026-11-09", "test")
        self.assertTrue(any("loops" in e for e in da.record_errors(d)))
        d = copy.deepcopy(REGISTER)
        by = {r["id"]: r for r in d["requirements"]}
        a = _active_decision(d)
        rej = next(r for r in d["requirements"] if da.lifecycle(r) == "REJECTED")
        a["disposition"] = "SUPERSEDED"
        da.link_supersession(by, a["id"], rej["id"], "2026-11-09", "test")
        for r in (a, rej):
            r["lifecycle"] = da.lifecycle(r)
        self.assertTrue(any("no record governs" in e for e in da.record_errors(d)))

    def test_conflicting_active_replacements_are_detected(self):
        d = copy.deepcopy(REGISTER)
        old = next(r for r in d["requirements"] if r.get("superseded_by")
                   and da.lifecycle(_by(d, r["superseded_by"])) != "SUPERSEDED")       # its replacement still governs
        rival = _active_decision(d, skip=(old["superseded_by"],))
        rival["supersedes"] = [old["id"]]
        errs = da.record_errors(d)
        self.assertTrue(any("conflicting active replacements" in e for e in errs))

    def test_governing_record_resolves_through_a_chain(self):
        by = {r["id"]: r for r in REGISTER["requirements"]}
        for r in REGISTER["requirements"]:
            if r.get("superseded_by"):
                g, chain, problem = da.governing(r, by)
                self.assertIsNone(problem)
                self.assertNotEqual(da.lifecycle(g), "SUPERSEDED")


class DocumentTest(unittest.TestCase):
    def _docs(self, extra=""):
        tmp = Path(tempfile.mkdtemp())
        for rel in da.ENTRY_POINTS:
            (tmp / rel).parent.mkdir(parents=True, exist_ok=True)
            (tmp / rel).write_text("The development line is `wip/b25r2-rev2`; records on `wip/requirements-control`.\n" + extra)
        return tmp

    def test_missing_current_authority_is_detected(self):
        d = copy.deepcopy(REGISTER)
        tmp = self._docs()
        (tmp / "docs/PROJECT_MEMORY.md").write_text("Read the records.\n")
        errs = da.document_errors(d, tmp)
        self.assertTrue(any("PROJECT_MEMORY" in e and "does not name the current development line" in e for e in errs))
        d.pop("authority")
        self.assertTrue(any("authority block" in e for e in da.document_errors(d, tmp)))

    def test_stale_recovery_instruction_is_detected(self):
        d = copy.deepcopy(REGISTER)
        tmp = self._docs("1. The code integration branch is `wip/expansion20`.\n")
        self.assertTrue(any("presents frozen branch wip/expansion20 as current" in e for e in da.document_errors(d, tmp)))
        tmp = self._docs("1. The code integration branch was `wip/expansion20` until 2026-11-03.\n")
        self.assertEqual(da.document_errors(d, tmp), [])
        tmp = self._docs("## Old section\n> **HISTORICAL.**\nIntegration branch: `wip/b25r1`.\n")
        self.assertEqual(da.document_errors(d, tmp), [])

    def test_acknowledged_stale_line_lapses_when_the_decision_is_made(self):
        d = copy.deepcopy(REGISTER)
        tmp = self._docs()
        (tmp / "CLAUDE.md").write_text("`wip/b25r2-rev2` `wip/requirements-control`\n- **One integration branch for code: `wip/expansion20`.**\n")
        self.assertEqual(da.document_errors(d, tmp), [])
        q = _by(d, d["authority"]["acknowledged_stale"][0]["decision"])
        q["disposition"], q["owner_answer"] = "APPROVED", "test"
        self.assertTrue(any("no longer under review" in e for e in da.document_errors(d, tmp)))


if __name__ == "__main__":
    unittest.main()
