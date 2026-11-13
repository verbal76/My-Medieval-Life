"""Check that this checkout has the git refs the register's path check reads, and that they are GitHub's (audit
docs/audits/2026-11-13_INHERITED_FAILURES_AUDIT.md).

tools/check_requirements.py decides whether a path named by a record exists by looking in the working tree and on the
integration branches in PATH_REFS (origin/staging/my-medieval-life and the old build and expansion branches). Its
answer therefore depends on which refs the checkout has:
  - a ref missing (a shallow CI clone that did not fetch it): the path is "undecidable" and silently not reported;
  - a ref present but not GitHub's: in a `git clone --shared /path/to/repo` the clone's origin/* are the source
    repository's LOCAL branches, which can be weeks behind GitHub. Build 40 a5a0b7c and the Build 41 candidate 0bbee94
    "failed" tests/test_requirements.py that way (2026-11-13): the source's local staging/my-medieval-life was at
    6607000 (2026-10-21), before docs/build18/PHASE_A_INVENTORY.md was added to staging (b518538, 2026-10-22).
This tool says which case applies before the tests are trusted, and how to fix it. It reads only; it changes nothing.

    python3 tools/check_test_env.py            # report; exit 1 if a ref is stale (a local clone behind its source)
    python3 tools/check_test_env.py --strict   # CI: also exit 1 if a ref is missing (the check would be undecidable)
"""
import argparse
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from check_requirements import PATH_REFS  # noqa: E402  (one list of refs, owned by the register check)


def git(*args, cwd=None):
    r = subprocess.run(["git", "-C", str(cwd or REPO)] + list(args), capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def local_source():
    """The source repository's path when origin is a local directory (a `git clone [--shared]` of a checkout), else None."""
    url = git("remote", "get-url", "origin")
    if not url or "://" in url or url.startswith("git@"):
        return None
    p = Path(url[len("file://"):] if url.startswith("file://") else url)
    return p if p.exists() else None


def check(refs=PATH_REFS):
    """[(ref, state, detail)]: state is ok, missing or stale. For a local clone a ref is compared with the source's own
    remote-tracking ref (refs/remotes/<ref>), which is what GitHub had at the source's last fetch."""
    src = local_source()
    rows = []
    for ref in refs:
        here = git("rev-parse", "-q", "--verify", ref + "^{commit}")
        if not here:
            rows.append((ref, "missing", "not in this checkout: paths on it cannot be decided"))
            continue
        when = git("log", "-1", "--format=%cs", here)
        if src is None:
            rows.append((ref, "ok", "%s (%s)" % (here[:9], when)))
            continue
        # in a clone of a local repository, origin/X is the source's LOCAL branch X; GitHub's copy is the source's origin/X
        theirs = git("rev-parse", "-q", "--verify", "refs/remotes/%s^{commit}" % ref, cwd=src)
        if theirs and theirs != here:
            rows.append((ref, "stale", "%s (%s) is the source's local branch; GitHub's copy in the source is %s (%s)"
                         % (here[:9], when, theirs[:9], git("log", "-1", "--format=%cs", theirs, cwd=src) or "?")))
        else:
            rows.append((ref, "ok", "%s (%s)" % (here[:9], when)))
    return src, rows


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--strict", action="store_true", help="also fail when a ref is missing (CI after its fetch step)")
    a = ap.parse_args(argv)
    src, rows = check()
    if src:
        print("origin is a local repository (%s): origin/* here are its local branches, not GitHub's" % src)
    for ref, state, detail in rows:
        print("%-8s %s: %s" % (state, ref, detail))
    stale = [r for r, s, _ in rows if s == "stale"]
    missing = [r for r, s, _ in rows if s == "missing"]
    if stale:
        print("FIX: git fetch origin %s" % " ".join("'+refs/remotes/%s:refs/remotes/%s'" % (r, r) for r in stale))
    if missing:
        print("FIX: git fetch origin %s   (CI: the 'Fetch the integration branches' step)"
              % " ".join("'%s:refs/remotes/%s'" % (r[len("origin/"):], r) for r in missing))
    bad = stale or (a.strict and missing)
    print("test environment: %s (%d refs, %d stale, %d missing)" % ("NOT LIKE CI" if bad else "ok", len(rows), len(stale),
                                                                     len(missing)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
