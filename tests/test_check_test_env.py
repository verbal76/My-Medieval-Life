"""tools/check_test_env.py and tools/check_unittest_skips.py (audit docs/audits/2026-11-13_INHERITED_FAILURES_AUDIT.md):
a clone whose origin/* lag GitHub is unfit and fixed by --fetch; a missing ref is unfit under --strict; `run` does not run
a command on an unfit environment; an unexpected unittest skip or a test count under the floor fails."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
import check_test_env as cte  # noqa: E402
import check_unittest_skips as cus  # noqa: E402


def run(*args, cwd):
    subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "init.defaultBranch=main",
                    "-c", "protocol.file.allow=always"] + list(args), cwd=cwd, check=True, capture_output=True)


class World:
    """gh: the authority (a bare repository, reached by a file:// URL); src: a working clone of it whose LOCAL branch
    'staging' is one commit behind gh's; clone: `git clone --shared src`, as the agents' /dev/shm checkouts are made."""

    def __init__(self, t):
        t = Path(t)
        self.gh, self.src, self.clone = t / "gh.git", t / "src", t / "clone"
        run("init", "-q", "--bare", str(self.gh), cwd=t)
        run("clone", "-q", self.gh.as_uri(), str(self.src), cwd=t)
        run("commit", "-q", "--allow-empty", "-m", "old", cwd=self.src)
        run("branch", "staging", cwd=self.src)                      # the source's local branch stays old
        run("commit", "-q", "--allow-empty", "-m", "new", cwd=self.src)
        run("push", "-q", "origin", "HEAD:refs/heads/staging", "HEAD:refs/heads/main", cwd=self.src)
        run("fetch", "-q", "origin", cwd=self.src)
        run("clone", "-q", "--shared", str(self.src), str(self.clone), cwd=t)
        self.new = subprocess.run(["git", "rev-parse", "HEAD"], cwd=self.src, capture_output=True, text=True).stdout.strip()

    def __enter__(self):
        self.saved = cte.REPO
        cte.REPO = self.clone
        return self

    def __exit__(self, *exc):
        cte.REPO = self.saved


class EnvironmentTest(unittest.TestCase):
    REFS = ["origin/staging", "origin/absent"]

    def test_a_lagging_shared_clone_is_stale_online_and_offline_and_fetch_makes_it_fit(self):
        with tempfile.TemporaryDirectory() as t, World(t) as w:
            self.assertEqual(cte.local_source().resolve(), w.src.resolve())
            self.assertEqual(cte.authority(), w.gh.as_uri())
            for offline in (True, False):
                _src, _url, rows = cte.check(self.REFS, offline=offline)
                self.assertEqual([r["state"] for r in rows], ["stale", "missing"], offline)
                self.assertTrue(cte.evaluate(rows))
            self.assertEqual(cte.fetch(["origin/staging"]), [])
            _src, _url, rows = cte.check(["origin/staging"])
            self.assertEqual((rows[0]["state"], rows[0]["sha"]), ("ok", w.new))
            self.assertEqual(cte.evaluate(rows, strict=True), [])

    def test_missing_ref_candidate_and_shallow_against_are_unfit(self):
        with tempfile.TemporaryDirectory() as t, World(t):
            cte.fetch(["origin/staging"])
            _src, _url, rows = cte.check(self.REFS)
            self.assertEqual(cte.evaluate(rows), [])                      # a missing ref is only unfit when strict
            self.assertEqual(len(cte.evaluate(rows, strict=True)), 1)
            self.assertEqual(len(cte.evaluate(rows[:1], candidate="0000000")), 1)
            self.assertEqual(len(cte.evaluate(rows[:1], require_commits=["HEAD~5"])), 1)

    def test_run_does_not_run_the_command_on_an_unfit_environment(self):
        with tempfile.TemporaryDirectory() as t, World(t) as w:
            out = Path(t) / "env.json"
            marker = Path(t) / "ran"
            old = cte.PATH_REFS
            cte.PATH_REFS = ["origin/staging"]
            try:
                code = cte.main(["--offline", "--record", str(out), "run", "--", "touch", str(marker)])
            finally:
                cte.PATH_REFS = old
            self.assertEqual(code, cte.ENV_EXIT)
            self.assertFalse(marker.exists())
            rec = json.loads(out.read_text())
            self.assertEqual((rec["verdict"], rec["classification"]), ("environment", "not run: environment"))
            self.assertEqual(rec["candidate"], w.new)


class SkipFloorTest(unittest.TestCase):
    class Result:
        def __init__(self, skipped):
            self.skipped = [(type("T", (), {"id": (lambda self, n=n: n)})(), "why") for n in skipped]

    def test_unexpected_skips_and_a_low_count_fail(self):
        expect = {"expected_skips": {"a.B.test_x": "needs X"}, "min_tests": 10}
        self.assertEqual(cus.problems(self.Result(["a.B.test_x"]), 10, expect), [])
        self.assertEqual(len(cus.problems(self.Result(["a.B.test_y"]), 10, expect)), 1)
        self.assertEqual(len(cus.problems(self.Result([]), 9, expect)), 1)

    def test_the_recorded_expectations_are_well_formed(self):
        e = json.loads(cus.EXPECT.read_text())
        self.assertEqual(e["format"], "mml-unittest-expectations/1")
        self.assertGreater(int(e["min_tests"]), 0)
        self.assertTrue(all(isinstance(v, str) and v for v in e["expected_skips"].values()))


if __name__ == "__main__":
    unittest.main()
