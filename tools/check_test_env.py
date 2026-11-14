"""Establish, check and record the git environment that the register check and the Python tests depend on, before their
results are trusted (audit docs/audits/2026-11-13_INHERITED_FAILURES_AUDIT.md; owner directive 2026-11-13 Build 42,
section 2: "A stale local branch must never again silently produce misleading validation failures").

tools/check_requirements.py decides whether a path named by a record exists by looking in the working tree and on the
integration branches in its PATH_REFS. Its answer therefore depends on which refs the checkout holds:
  - a ref missing (a shallow CI clone that did not fetch it): the path is "undecidable" and silently not reported;
  - a ref present but not GitHub's: in a `git clone --shared /path/to/repo` the clone's origin/* are the source
    repository's LOCAL branches, which can be weeks behind GitHub. Build 40 a5a0b7c and the Build 41 candidate 0bbee94
    "failed" tests/test_requirements.py that way (2026-11-13): the source's local staging/my-medieval-life was 6607000
    (2026-10-21), before docs/build18/PHASE_A_INVENTORY.md was added to staging (b518538, 2026-10-22).
`--against REF` reads the register at REF: a REF that does not resolve (HEAD~1 in a depth-1 clone) is only a note.

The required refs are read from check_requirements.PATH_REFS of THIS tree (one list; CI fetches what this prints), so a
branch added to PATH_REFS cannot be left out of the fetch. The authority is GitHub: origin's URL, or, when origin is a
local directory, that directory's own origin URL.

Each ref is ok (equal to the authority), stale (differs from it), missing, or unverified (the authority was not asked or
could not be reached). A verdict of "environment" means the checkout is not fit for the dependent tests: their failures
there are ENVIRONMENT failures, not defects, and the tests are not run by `run`.

    python3 tools/check_test_env.py                         # check against the authority (git ls-remote); exit 1 if unfit
    python3 tools/check_test_env.py --fetch                 # first fetch every required ref from the authority
    python3 tools/check_test_env.py --list-refs             # the branch names to fetch (CI)
    python3 tools/check_test_env.py --fetch --candidate SHA --require-commit HEAD~1 --record out/test-env.json
    python3 tools/check_test_env.py --fetch --record out/test-env.json run -- python3 -m unittest discover -s tests
      # the command runs only on a fit environment; its exit status is returned and recorded with the environment
    python3 tools/check_test_env.py --offline               # no network: compare a local clone with its source only
"""
import argparse
import datetime
import json
import platform
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from check_requirements import PATH_REFS  # noqa: E402  (one list of refs, owned by the register check)

FORMAT = "mml-test-env/1"
ENV_EXIT = 3          # `run`: the environment is unfit, the command was not run


def git(*args, cwd=None):
    r = subprocess.run(["git", "-C", str(cwd or REPO)] + list(args), capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def is_url(u):
    return bool(u) and ("://" in u or re.match(r"^[\w.-]+@[\w.-]+:", u) is not None)


def public_url(u):
    """The URL without any credentials (never recorded)."""
    return re.sub(r"//[^/@]*@", "//", u) if u else u


def local_source():
    """The source repository's path when origin is a local directory (a `git clone [--shared]` of a checkout), else None."""
    url = git("remote", "get-url", "origin")
    if not url or is_url(url):
        return None
    p = Path(url[len("file://"):] if url.startswith("file://") else url)
    return p if p.exists() else None


def authority():
    """The authoritative remote's URL: origin's, or a local source's own origin."""
    src = local_source()
    if src is not None:
        u = git("remote", "get-url", "origin", cwd=src)
        return u if is_url(u) else None
    return git("remote", "get-url", "origin")


def branches(refs=None):
    return [r[len("origin/"):] for r in (refs or PATH_REFS)]


def fetch(refs=None, url=None):
    """Fetch each required branch from the authority into refs/remotes/origin/* (depth 1 in a shallow clone)."""
    url = url or authority()
    shallow = git("rev-parse", "--is-shallow-repository") == "true"
    failed = []
    for b in branches(refs):
        cmd = ["fetch", "-q"] + (["--depth=1"] if shallow else []) + [url, "+refs/heads/%s:refs/remotes/origin/%s" % (b, b)]
        if git(*cmd) is None:
            failed.append(b)
    return failed


def remote_heads(url, refs=None):
    """{branch: sha} from the authority, or None when it cannot be reached."""
    if not url:
        return None
    try:
        r = subprocess.run(["git", "-C", str(REPO), "ls-remote", url] + ["refs/heads/%s" % b for b in branches(refs)],
                           capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return None
    if r.returncode != 0:
        return None
    return {line.split("\t")[1][len("refs/heads/"):]: line.split("\t")[0] for line in r.stdout.splitlines() if "\t" in line}


def check(refs=None, offline=False):
    """(src, url, rows): each row {ref, sha, date, authority_sha, state, detail}. With network, the authority is asked
    (git ls-remote). Offline, a local clone is compared with its source's own remote-tracking refs (what GitHub had at the
    source's last fetch); a ref nothing can be compared with is 'unverified'."""
    refs = refs or PATH_REFS
    src = local_source()
    url = None if offline else authority()
    heads = None if offline else remote_heads(url, refs)
    rows = []
    for ref in refs:
        here = git("rev-parse", "-q", "--verify", ref + "^{commit}")
        row = {"ref": ref, "sha": here, "date": git("log", "-1", "--format=%cs", here) if here else None,
               "authority_sha": None}
        if heads is not None:
            row["authority_sha"] = heads.get(ref[len("origin/"):])
        elif src is not None:
            row["authority_sha"] = git("rev-parse", "-q", "--verify", "refs/remotes/%s^{commit}" % ref, cwd=src)
        if not here:
            row["state"], row["detail"] = "missing", "not in this checkout: paths on it cannot be decided"
        elif row["authority_sha"] is None:
            row["state"] = "unverified"
            row["detail"] = "not compared with the authority (%s)" % ("offline" if offline else "unreachable or no such branch")
        elif row["authority_sha"] != here:
            row["state"] = "stale"
            row["detail"] = "%s (%s) here; the authority has %s%s" % (
                here[:9], row["date"], row["authority_sha"][:9],
                " (this is the source's local branch)" if src is not None else "")
        else:
            row["state"], row["detail"] = "ok", "%s (%s)" % (here[:9], row["date"])
        rows.append(row)
    return src, url, rows


def evaluate(rows, strict=False, candidate=None, require_commits=(), require_authority=False):
    """The problems that make the environment unfit (empty: fit)."""
    problems = []
    for r in rows:
        if r["state"] == "stale":
            problems.append("stale %s: %s" % (r["ref"], r["detail"]))
        elif r["state"] == "missing" and strict:
            problems.append("missing %s: the register's path check would be undecidable" % r["ref"])
        elif r["state"] == "unverified" and require_authority:
            problems.append("unverified %s: %s" % (r["ref"], r["detail"]))
    head = git("rev-parse", "HEAD")
    if candidate and not (head or "").startswith(candidate.lower()):
        problems.append("HEAD is %s, not the candidate %s" % ((head or "?")[:9], candidate))
    for c in require_commits:
        if not git("rev-parse", "-q", "--verify", c + "^{commit}"):
            problems.append("%s does not resolve (a clone too shallow for --against %s)" % (c, c))
    return problems


def record(path, src, url, rows, problems, args, command=None, exit_code=None):
    head = git("rev-parse", "HEAD")
    rec = {"format": FORMAT,
           "checked_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
           "candidate": head, "candidate_requested": args.candidate, "branch": git("rev-parse", "--abbrev-ref", "HEAD"),
           "tracked_changes": bool(git("status", "--porcelain", "--untracked-files=no")),
           "authority": public_url(url), "local_source": str(src) if src else None,
           "shallow": git("rev-parse", "--is-shallow-repository") == "true",
           "required_refs": rows, "required_commits": list(args.require_commit or []),
           "verdict": "environment" if problems else "fit", "problems": problems,
           "git": git("--version"), "python": platform.python_version()}
    if command is not None:
        rec["command"], rec["exit_code"] = command, exit_code
        rec["classification"] = ("not run: environment" if problems else
                                 "passed" if exit_code == 0 else "failed on a fit environment: a candidate defect")
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(rec, indent=1) + "\n")


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    command = None
    if "run" in argv:
        i = argv.index("run")
        command = argv[i + 1:]
        argv = argv[:i]
        if command[:1] == ["--"]:
            command = command[1:]
        if not command:
            print("run: give the command after 'run --'")
            return 2
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--list-refs", action="store_true", help="print the branch names to fetch, one a line, and stop")
    ap.add_argument("--fetch", action="store_true", help="fetch every required ref from the authority first")
    ap.add_argument("--strict", action="store_true", help="also unfit when a ref is missing (the path check undecidable)")
    ap.add_argument("--offline", action="store_true", help="do not ask the authority (compare a local clone with its source)")
    ap.add_argument("--require-authority", action="store_true", help="also unfit when a ref could not be compared")
    ap.add_argument("--candidate", help="the commit under test: unfit if HEAD is another")
    ap.add_argument("--require-commit", action="append", metavar="REV", help="a commit that must resolve (e.g. HEAD~1)")
    ap.add_argument("--record", metavar="FILE", help="write the environment record (%s) here" % FORMAT)
    a = ap.parse_args(argv)
    if a.list_refs:
        print("\n".join(branches()))
        return 0
    if a.fetch:
        failed = fetch()
        for b in failed:
            print("fetch failed: %s" % b)
    src, url, rows = check(offline=a.offline)
    if src:
        print("origin is a local repository (%s): its origin/* are that repository's local branches" % src)
    print("authority: %s" % (public_url(url) or "none (offline)"))
    for r in rows:
        print("%-10s %s: %s" % (r["state"], r["ref"], r["detail"]))
    problems = evaluate(rows, a.strict or a.fetch, a.candidate, a.require_commit or (), a.require_authority)
    stale = [r["ref"] for r in rows if r["state"] == "stale"]
    if stale or any(r["state"] == "missing" for r in rows):
        print("FIX: python3 tools/check_test_env.py --fetch   (fetches %s from %s)"
              % (" ".join(branches()), public_url(url) or "the authority"))
    for p in problems:
        print("problem: %s" % p)
    print("test environment: %s (%d refs: %s)" % (
        "UNFIT, failures of dependent tests here are ENVIRONMENT failures" if problems else "fit", len(rows),
        ", ".join("%d %s" % (sum(r["state"] == s for r in rows), s) for s in ("ok", "stale", "missing", "unverified"))))
    if command is None:
        if a.record:
            record(a.record, src, url, rows, problems, a)
        return 1 if problems else 0
    if problems:
        print("run: NOT RUN (environment): %s" % " ".join(command))
        if a.record:
            record(a.record, src, url, rows, problems, a, command, None)
        return ENV_EXIT
    code = subprocess.run(command, cwd=REPO).returncode
    print("run: exit %d on a fit environment%s" % (code, "" if code == 0 else ": a candidate defect, not an environment failure"))
    if a.record:
        record(a.record, src, url, rows, problems, a, command, code)
    return code


if __name__ == "__main__":
    sys.exit(main())
