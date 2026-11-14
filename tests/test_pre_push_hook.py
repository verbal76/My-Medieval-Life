"""tools/git_hooks/pre-push, the register rule for code branches (REQ-CTRL-01/02; Build 42 env guard, 2026-11-14): a pushed
register must be a version wip/requirements-control or staging has had, read from the authority, and a fetch that fails
refuses the push instead of judging against an old local copy."""
import subprocess
import tempfile
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parent.parent / "tools" / "git_hooks" / "pre-push"
REG = "docs/requirements/requirements.json"
ZERO = "0" * 40


def git(*args, cwd):
    return subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "init.defaultBranch=main",
                           "-c", "protocol.file.allow=always"] + list(args),
                          cwd=cwd, check=True, capture_output=True, text=True).stdout.strip()


def commit_register(repo, text, msg):
    (repo / REG).parent.mkdir(parents=True, exist_ok=True)
    (repo / REG).write_text(text)
    git("add", REG, cwd=repo)
    git("commit", "-q", "-m", msg, cwd=repo)
    return git("rev-parse", "HEAD", cwd=repo)


class RegisterRuleTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        t = Path(self.tmp.name)
        self.gh, work, self.clone = t / "gh.git", t / "work", t / "clone"
        git("init", "-q", "--bare", str(self.gh), cwd=t)
        git("clone", "-q", self.gh.as_uri(), str(work), cwd=t)
        commit_register(work, '{"v": 1}\n', "v1")
        git("push", "-q", "origin", "HEAD:refs/heads/staging/my-medieval-life", cwd=work)
        commit_register(work, '{"v": 2}\n', "v2 on the records branch only (staging is frozen)")
        git("push", "-q", "origin", "HEAD:refs/heads/wip/requirements-control", cwd=work)
        git("clone", "-q", self.gh.as_uri(), str(self.clone), cwd=t)
        git("checkout", "-q", "-b", "code", "origin/staging/my-medieval-life", cwd=self.clone)

    def tearDown(self):
        self.tmp.cleanup()

    def push(self, sha):
        r = subprocess.run(["sh", str(HOOK)], cwd=self.clone, capture_output=True, text=True,
                           input="refs/heads/code %s refs/heads/wip/code %s\n" % (sha, ZERO))
        return r.returncode, r.stderr

    def test_a_records_branch_version_is_accepted(self):
        self.assertEqual(self.push(commit_register(self.clone, '{"v": 2}\n', "sync from records"))[0], 0)

    def test_a_staging_version_is_accepted(self):
        self.assertEqual(self.push(git("rev-parse", "HEAD", cwd=self.clone))[0], 0)   # the branch carries staging's v1

    def test_a_version_neither_branch_had_is_refused(self):
        code, err = self.push(commit_register(self.clone, '{"v": 3}\n', "edited on a code branch"))
        self.assertEqual(code, 1)
        self.assertIn("neither wip/requirements-control nor staging", err)

    def test_an_unreachable_authority_refuses(self):
        sha = commit_register(self.clone, '{"v": 2}\n', "sync from records")
        git("remote", "set-url", "origin", (Path(self.tmp.name) / "gone.git").as_uri(), cwd=self.clone)
        code, err = self.push(sha)
        self.assertEqual(code, 1)
        self.assertIn("could not fetch", err)


if __name__ == "__main__":
    unittest.main()
