"""Run the Python unit tests (tests/) and fail when a test is skipped that is not expected to be, or when fewer tests run
than the recorded floor (audit docs/audits/2026-11-13_INHERITED_FAILURES_AUDIT.md). `unittest` reports a skip as
"OK (skipped=N)" and exits 0, so a test that silently stops running (a missing tool, environment or ref) would otherwise
pass every gate. The expected skips and the floor are in tools/unittest_expectations.json (mml-unittest-expectations/1);
like tools/ci_check_floors.json, lowering the floor or adding an expected skip needs its reason in the same commit.

    python3 tools/check_unittest_skips.py            # instead of: python3 -m unittest discover -s tests
"""
import json
import sys
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXPECT = REPO / "tools" / "unittest_expectations.json"


def problems(result, ran, expect):
    """The reasons to fail beyond the tests' own failures: unexpected skips and a test count under the floor."""
    allowed = expect.get("expected_skips", {})
    out = []
    for test, reason in result.skipped:
        if test.id() not in allowed:
            out.append("unexpected skip: %s (%s); expected skips are listed in %s" % (test.id(), reason, EXPECT.name))
    if ran < int(expect.get("min_tests", 0)):
        out.append("ran %d tests, fewer than the floor of %d (%s): tests were removed or not collected"
                   % (ran, expect["min_tests"], EXPECT.name))
    return out


def main():
    expect = json.loads(EXPECT.read_text())
    suite = unittest.defaultTestLoader.discover(str(REPO / "tests"))
    result = unittest.TextTestRunner(verbosity=1).run(suite)
    skipped = {t.id() for t, _ in result.skipped}
    for name in sorted(set(expect.get("expected_skips", {})) - skipped):
        print("note: expected skip %s ran (its condition was met)" % name)
    bad = problems(result, result.testsRun, expect)
    for p in bad:
        print("FAIL " + p)
    print("unittest: %d tests, %d failures, %d errors, %d skipped (%d unexpected)"
          % (result.testsRun, len(result.failures), len(result.errors), len(result.skipped),
             sum(p.startswith("unexpected") for p in bad)))
    return 0 if result.wasSuccessful() and not bad else 1


if __name__ == "__main__":
    sys.exit(main())
