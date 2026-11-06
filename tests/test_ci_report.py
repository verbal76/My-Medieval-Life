"""Tests for tools/ci_report.py: every suite runs past a failure, and the report never turns a failure into success."""

import json
import os
import shlex
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
import ci_report  # noqa: E402

PASS = "-c \"print('12 checks, 0 failures')\""
FAIL = "-c \"import sys; print('FAIL: the second check'); print('5 checks, 1 failures'); sys.exit(1)\""
TOLERATED = "-c \"print('FAIL: x'); print('3 checks, 2 failures')\""
SCRIPT_ERR = "-c \"print('SCRIPT ERROR: boom'); print('1 checks, 0 failures')\""


class CiReportTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = self.tmp.name
        self.results = os.path.join(self.dir, "results.jsonl")

    def tearDown(self):
        self.tmp.cleanup()

    def run_list(self, lines, group="game", extra=()):
        path = os.path.join(self.dir, group + ".txt")
        with open(path, "w") as f:
            f.write("# a comment\n\n" + "\n".join(lines) + "\n")
        prefix = shlex.quote(sys.executable)
        argv = ["run", "--group", group, "--list", path, "--prefix", prefix, "--logs", os.path.join(self.dir, "logs"),
                "--results", self.results] + list(extra)
        stdout = sys.stdout
        sys.stdout = open(os.devnull, "w")
        try:
            return ci_report.main(argv)
        finally:
            sys.stdout.close()
            sys.stdout = stdout

    def recs(self):
        return ci_report.load_results([self.results])

    def test_runs_every_suite_after_a_failure_and_fails_the_step(self):
        self.assertEqual(self.run_list([PASS, FAIL, PASS]), 1)
        recs = self.recs()
        self.assertEqual([r["status"] for r in recs], ["passed", "failed", "passed"])
        self.assertEqual(recs[1]["checks"], 5)
        self.assertEqual(recs[1]["failures"], 1)
        self.assertIn("FAIL: the second check", recs[1]["first_failures"])

    def test_all_passing_is_tested_never_validated(self):
        self.assertEqual(self.run_list([PASS, PASS]), 0)
        rep = ci_report.build_report(self.recs(), ["game"], {"game": "success"}, env={})
        self.assertEqual(rep["outcome"], "TESTED")
        self.assertEqual(rep["format"], "mml-ci-report/1")
        self.assertEqual(rep["totals"]["attempted"], 2)
        md = ci_report.render_markdown(rep)
        self.assertNotIn("VALIDATED\n", md.split("It is not")[0])

    def test_a_failure_is_reported_failed(self):
        self.run_list([FAIL])
        rep = ci_report.build_report(self.recs(), ["game"], {"game": "failure"}, env={})
        self.assertEqual(rep["outcome"], "FAILED")
        self.assertEqual(rep["failures"][0]["exit_code"], 1)

    def test_missing_group_is_incomplete_not_tested(self):
        self.run_list([PASS])
        rep = ci_report.build_report(self.recs(), ["game", "python"], {"game": "success"}, env={})
        self.assertEqual(rep["outcome"], "INCOMPLETE")
        self.assertTrue(rep["missing_evidence"])

    def test_failed_step_without_a_suite_result_is_failed(self):
        rep = ci_report.build_report([], ["game"], {"import": "failure", "game": "skipped"}, env={})
        self.assertEqual(rep["outcome"], "FAILED")

    def test_printed_failures_fail_even_with_exit_0(self):
        # TEST-GOV-01: before, a suite that printed failures but exited 0 only earned a warning
        self.assertEqual(self.run_list([TOLERATED]), 1)
        self.assertEqual(self.recs()[0]["status"], "failed")

    def test_no_count_line_fails_when_counts_are_required(self):
        nocount = "-c \"print('all good')\""
        self.assertEqual(self.run_list([nocount]), 0)
        self.assertEqual(self.run_list([nocount], extra=["--require-counts"]), 1)

    def test_fewer_checks_than_the_floor_fail(self):
        # the chapel_test case: a suite stopped early (here 9 of 12 checks) exits 0 and passed
        early = "-c \"print('9 checks, 0 failures')\""
        floors = os.path.join(self.dir, "floors.json")
        with open(floors, "w") as f:
            json.dump({"_note": "x", ci_report.suite_name(shlex.split(early)): 12, ci_report.suite_name(shlex.split(PASS)): 12}, f)
        self.assertEqual(self.run_list([PASS], extra=["--floors", floors]), 0)
        self.assertEqual(self.run_list([early], extra=["--floors", floors]), 1)
        self.assertIn("floor", " ".join(self.recs()[-1]["reasons"]))

    def test_script_errors_fail_only_when_asked(self):
        self.assertEqual(self.run_list([SCRIPT_ERR]), 0)
        self.assertEqual(self.run_list([SCRIPT_ERR], group="sim", extra=["--fail-on-script-errors"]), 1)

    def test_timeout_is_a_failure(self):
        self.assertEqual(self.run_list(["-c \"import time; time.sleep(5)\""], extra=["--timeout", "1"]), 1)
        self.assertEqual(self.recs()[0]["status"], "timeout")

    def test_names(self):
        self.assertEqual(ci_report.suite_name(["res://tests/world_test.gd"]), "world_test")
        self.assertEqual(ci_report.suite_name(["res://tests/judgment_perf.gd", "--", "--sizes", "100"]), "judgment_perf")
        self.assertEqual(ci_report.suite_name(["python3", "-m", "unittest", "discover"]), "unittest discover")

    def test_unittest_counts(self):
        log = "....\nRan 168 tests in 3.2s\n\nFAILED (failures=2, errors=1)\n"
        checks, failures, _ = ci_report.read_counts(log)
        self.assertEqual((checks, failures), (168, 3))


if __name__ == "__main__":
    unittest.main()
