"""Audit worker branches against the one integration branch (owner directive BRANCH-POL-01, 2026-11-02).

For every worker branch it reports, from content rather than ahead/behind counts:
- UNIQUE or INTEGRATED: whether merging the branch would change the integration branch's tree at all
  (`git merge-tree --write-tree`), and the size of that change;
- the branch's base: how many integration commits landed since it forked (a stale base needs the integration
  branch merged in before its work is submitted);
- the files it changes since its base, and every file two active branches both change (overlapping ownership);
- with --worktrees, uncommitted files in each local worktree, so nothing unpushed is mistaken for absent work; those
  files count as the branch's own for the overlap check.

Run from any checkout after `git fetch origin`:

    python3 tools/branch_audit.py                       # worker branches pushed in the last 3 days
    python3 tools/branch_audit.py --days 1 --worktrees
    python3 tools/branch_audit.py --branches wip/b25-home-door wip/b25-farm-phase2

It only reads; it changes no branch, worktree or file. Exit status 1 when two active branches overlap or a
branch's base is more than --stale commits behind, so it can gate a merge.
"""
import argparse
import subprocess
import sys
import time

INTEGRATION = "wip/expansion20"
# Long-lived lines that are not worker branches (CLAUDE.md section 5): the records branch is owner-isolated, the
# others are history or the owner's.
NOT_WORKERS = {"main", "staging/my-medieval-life", "wip/requirements-control", INTEGRATION}


def git(*args, check=True):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    if check and r.returncode not in (0, 1):
        raise SystemExit(f"git {' '.join(args)} failed: {r.stderr.strip()}")
    return r.stdout.strip()


def changed_files(base, ref):
    out = git("diff", "--name-only", base, ref)
    return set(out.splitlines()) if out else set()


def audit(branches, integration, stale_limit, local=None):
    tip = f"origin/{integration}"
    tip_tree = git("rev-parse", f"{tip}^{{tree}}")
    rows, owned, problems = [], {}, []
    for b in branches:
        ref = f"origin/{b}"
        base = git("merge-base", tip, ref)
        behind = int(git("rev-list", "--count", f"{base}..{tip}") or 0)
        merged = git("merge-tree", "--write-tree", tip, ref, check=False).splitlines()
        tree = merged[0] if merged else ""
        if tree == tip_tree:
            state = "INTEGRATED"
        else:
            stat = git("diff", "--shortstat", tip_tree, tree) if tree else "conflicts"
            state = f"UNIQUE ({stat.strip()})"
        files = changed_files(base, ref) | (local or {}).get(b, set())
        if state != "INTEGRATED" or (local or {}).get(b):
            owned[b] = files
            if behind > stale_limit:
                problems.append(f"{b}: base {base[:8]} is {behind} integration commits behind; merge {integration} in")
        rows.append((b, git("rev-parse", "--short", ref), base[:8], behind, state))
    names = sorted(owned)
    for i, a in enumerate(names):
        for c in names[i + 1:]:
            both = sorted(owned[a] & owned[c])
            if both:
                problems.append(f"overlap {a} / {c}: {', '.join(both)}")
    return rows, problems


def worker_branches(days):
    since = time.time() - days * 86400
    out = git("for-each-ref", "--format=%(refname:short) %(committerdate:unix)", "refs/remotes/origin")
    found = []
    for line in out.splitlines():
        name, when = line.rsplit(" ", 1)
        name = name.removeprefix("origin/")
        if name == "HEAD" or name in NOT_WORKERS or int(when) < since:
            continue
        found.append(name)
    return sorted(found)


def worktrees():
    out = git("worktree", "list", "--porcelain")
    paths = [l.split(" ", 1)[1] for l in out.splitlines() if l.startswith("worktree ")]
    res = []
    for p in paths:
        dirty = subprocess.run(["git", "-C", p, "status", "--porcelain"], capture_output=True, text=True).stdout
        n = len([l for l in dirty.splitlines() if l.strip()])
        head = subprocess.run(["git", "-C", p, "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True, text=True).stdout.strip()
        if n:
            res.append((p, head, n, {l[3:].strip() for l in dirty.splitlines() if l.strip()}))
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--integration", default=INTEGRATION)
    ap.add_argument("--branches", nargs="*")
    ap.add_argument("--days", type=float, default=3)
    ap.add_argument("--stale", type=int, default=20, help="integration commits a base may lag before it is reported")
    ap.add_argument("--worktrees", action="store_true")
    a = ap.parse_args()
    branches = a.branches or worker_branches(a.days)
    print(f"integration origin/{a.integration} {git('rev-parse', '--short', 'origin/' + a.integration)}")
    trees = worktrees() if a.worktrees else []
    local = {head: files for _, head, _, files in trees}
    rows, problems = audit(branches, a.integration, a.stale, local)
    for b, head, base, behind, state in rows:
        print(f"  {b:34} {head}  base {base} (+{behind} on integration)  {state}")
    if a.worktrees:
        print("worktrees with uncommitted files:")
        for p, head, n, _ in trees:
            print(f"  {p} [{head}] {n} files")
    for p in problems:
        print("PROBLEM " + p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
