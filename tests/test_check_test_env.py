"""tools/check_test_env.py: a clone of a local repository whose origin/* lag the source's GitHub refs is reported stale
(the cause of the 2026-11-13 "inherited" tests/test_requirements.py failures, docs/audits/2026-11-13_INHERITED_FAILURES_AUDIT.md)."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
import check_test_env as cte  # noqa: E402


def run(*args, cwd):
    subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "init.defaultBranch=main"] + list(args),
                   cwd=cwd, check=True, capture_output=True)


class StaleRefTest(unittest.TestCase):
    def test_shared_clone_with_a_lagging_local_branch_is_stale_and_a_missing_ref_is_missing(self):
        with tempfile.TemporaryDirectory() as t:
            src, clone = Path(t) / "src", Path(t) / "clone"
            src.mkdir()
            run("init", "-q", cwd=src)
            run("commit", "-q", "--allow-empty", "-m", "old", cwd=src)
            run("branch", "staging", cwd=src)                       # the source's local branch stays old
            run("commit", "-q", "--allow-empty", "-m", "new", cwd=src)
            run("update-ref", "refs/remotes/origin/staging", "HEAD", cwd=src)   # what GitHub has, as the source last fetched
            run("clone", "-q", "--shared", str(src), str(clone), cwd=t)
            old_repo = cte.REPO
            cte.REPO = clone
            try:
                found, rows = cte.check(["origin/staging", "origin/absent"])
            finally:
                cte.REPO = old_repo
            self.assertEqual(found.resolve(), src.resolve())
            self.assertEqual([(r, s) for r, s, _ in rows], [("origin/staging", "stale"), ("origin/absent", "missing")])


if __name__ == "__main__":
    unittest.main()
