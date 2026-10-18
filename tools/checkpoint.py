"""Back up all development work and prove the backup can be restored (owner's work-preservation rule).

Writes into a backup directory (default ~/mml-backups, outside the repository):
  <stamp>.bundle              every branch and commit, local ones included (git bundle --all)
  <stamp>-<tree>.patch        uncommitted changes to tracked files, per working tree (the main
                              checkout and each agent worktree), binary-safe
  <stamp>-<tree>-new.tar.gz   untracked, not-ignored files in that working tree
and then verifies them: the bundle passes `git bundle verify`, a clone of it has the same commit
as each tree's HEAD, and each patch applies cleanly to that commit (`git apply --check`).

Nothing is pushed anywhere. Restore with:
  git clone <stamp>.bundle restored && cd restored && git checkout <branch>
  git apply <stamp>-<tree>.patch && tar xzf <stamp>-<tree>-new.tar.gz

    python3 tools/checkpoint.py [--dir DIR] [--keep N]     (keeps the newest N checkpoints, default 5)

Day-to-day preservation (owner, standing authorization): push to GitHub
    python3 tools/checkpoint.py --push [--wip agent-x,agent-y]
pushes the current branch to staging/my-medieval-life (never forced; tools/git_hooks/pre-push also
refuses force and deletion) and each named agent worktree's uncommitted work, as a snapshot commit,
to wip/<worktree name>, then checks that every remote hash equals the local one.

Off-machine package for disaster recovery (owner's rule: at least one verified copy off the cloud machine):
    python3 tools/checkpoint.py --offsite DIR
records every agent worktree's uncommitted work (untracked files included) as a snapshot commit
under refs/backup/agent-<name> without touching the worktree, points refs/backup/<branch> at HEAD,
and writes into DIR a git bundle of everything GitHub does not have yet (HEAD and the snapshots,
on top of the branch's remote-tracking ref), the same bundle as base64 text (mml-<stamp>-bundle.b64.txt)
and a README with its sha256 and the restore steps; it checks that the text decodes back to the
verified bundle. The lead agent then uploads the two text files to the "Medieval Life Backups"
artifact, downloads the bundle back from there and restores it into a fresh GitHub clone
(CLAUDE.md, section 5). Secrets never go in: the bundle holds only tracked and untracked,
not-ignored project files.
"""
import base64
import hashlib
import datetime
import os
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def git(*args, cwd=REPO, check=True, binary=False):
    out = subprocess.run(["git", *args], cwd=cwd, check=check, capture_output=True)
    return out.stdout if binary else out.stdout.decode().strip()


def worktrees():
    """(name, path, head) for the main checkout and every agent worktree."""
    out, cur = [], {}
    for line in git("worktree", "list", "--porcelain").splitlines() + [""]:
        if line.startswith("worktree "):
            cur = {"path": Path(line[9:])}
        elif line.startswith("HEAD "):
            cur["head"] = line[5:]
        elif line == "" and cur:
            name = "main" if cur["path"] == REPO else cur["path"].name
            out.append((name, cur["path"], cur["head"]))
            cur = {}
    return out


def checkpoint(dest: Path) -> list:
    dest.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    bundle = dest / f"mml-{stamp}.bundle"
    git("bundle", "create", str(bundle), "--all")
    saved = [bundle]
    trees = worktrees()
    for name, path, _head in trees:
        patch = git("diff", "HEAD", "--binary", cwd=path, binary=True)
        if patch:
            p = dest / f"mml-{stamp}-{name}.patch"
            p.write_bytes(patch)
            saved.append(p)
        new = [f for f in git("ls-files", "--others", "--exclude-standard", cwd=path).splitlines() if f]
        if new:
            t = dest / f"mml-{stamp}-{name}-new.tar.gz"
            with tarfile.open(t, "w:gz") as tar:
                for f in new:
                    tar.add(path / f, arcname=f)
            saved.append(t)
    verify(bundle, trees, dest, stamp)
    return saved


def verify(bundle: Path, trees, dest: Path, stamp: str) -> None:
    git("bundle", "verify", str(bundle))
    with tempfile.TemporaryDirectory() as tmp:
        clone = Path(tmp) / "restored"
        subprocess.run(["git", "clone", "-q", "--no-checkout", str(bundle), str(clone)], check=True)
        for name, _path, head in trees:
            git("cat-file", "-e", head + "^{commit}", cwd=clone)          # the commit is in the bundle
            patch = dest / f"mml-{stamp}-{name}.patch"
            if patch.exists():
                git("checkout", "-q", "--detach", head, cwd=clone)
                git("apply", "--check", str(patch), cwd=clone)
            new = dest / f"mml-{stamp}-{name}-new.tar.gz"
            if new.exists():
                with tarfile.open(new) as tar:
                    tar.getmembers()                                     # readable


def snapshot(path: Path, name: str, previous: str = "") -> str:
    """A commit of a working tree's current state (untracked files included) on top of its HEAD,
    made through a temporary index so the tree and its own index are untouched. The previous
    snapshot, if any, is a second parent, so a WIP branch only ever moves forward; an unchanged
    tree returns the previous snapshot."""
    with tempfile.TemporaryDirectory() as tmp:
        env = {**os.environ, "GIT_INDEX_FILE": str(Path(tmp) / "index")}
        run = lambda *a: subprocess.run(["git", *a], cwd=path, env=env, check=True, capture_output=True).stdout.decode().strip()
        head = run("rev-parse", "HEAD")
        run("read-tree", head)
        run("add", "-A")
        tree = run("write-tree")
        if previous and run("rev-parse", previous + "^{tree}") == tree:
            return previous
        parents = ["-p", head] + (["-p", previous] if previous and previous != head else [])
        return run("commit-tree", tree, *parents, "-m", f"WIP snapshot of {name}'s uncommitted work")


def _ref(name: str) -> str:
    return git("rev-parse", "--verify", "--quiet", name, check=False)


STAGING = "staging/my-medieval-life"


def push(wip: list) -> list:
    """Push the current branch's commits to the staging branch (never forced) and each named
    worktree's uncommitted work to its own wip/<name> branch, then check the remote hashes."""
    pushed = [("HEAD", git("rev-parse", "HEAD"), f"refs/heads/{STAGING}")]
    trees = {name: path for name, path, _head in worktrees()}
    for name in wip:
        sha = snapshot(trees[name], name, _ref(f"refs/backup/{name}"))
        git("update-ref", f"refs/backup/{name}", sha)
        pushed.append((name, sha, f"refs/heads/wip/{name}"))
    main = trees.get("main")
    if main and git("status", "--porcelain", cwd=main):
        sha = snapshot(main, "the main checkout", _ref("refs/backup/main-uncommitted"))
        git("update-ref", "refs/backup/main-uncommitted", sha)
        pushed.append(("main checkout", sha, "refs/heads/wip/main-uncommitted"))
    git("push", "origin", *[f"{sha}:{ref}" for _n, sha, ref in pushed])
    remote = dict(line.split("\t")[::-1] for line in git("ls-remote", "origin", *[r for _n, _s, r in pushed]).splitlines())
    for name, sha, ref in pushed:
        if remote.get(ref) != sha:
            raise SystemExit(f"remote {ref} is {remote.get(ref)}, expected {sha} ({name})")
    return pushed


def offsite(dest: Path) -> list:
    dest.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d-%H%MZ")
    branch = git("rev-parse", "--abbrev-ref", "HEAD")
    remote = f"origin/{branch}"
    git("update-ref", f"refs/backup/{branch.split('/')[-1]}", "HEAD")
    refs = [f"refs/heads/{branch}", f"refs/backup/{branch.split('/')[-1]}"]
    for name, path, _head in worktrees():
        if name == "main":
            if git("status", "--porcelain", cwd=path):
                git("update-ref", "refs/backup/main-uncommitted", snapshot(path, "the main checkout", _ref("refs/backup/main-uncommitted")))
                refs.append("refs/backup/main-uncommitted")
            continue
        git("update-ref", f"refs/backup/{name}", snapshot(path, name, _ref(f"refs/backup/{name}")))
        refs.append(f"refs/backup/{name}")
    bundle = dest / f"mml-{stamp}.bundle"
    have = git("rev-parse", "--verify", "--quiet", remote, check=False)
    git("bundle", "create", str(bundle), *([f"^{remote}"] if have else []), *refs)
    git("bundle", "verify", str(bundle))
    raw = bundle.read_bytes()
    text = dest / f"mml-{stamp}-bundle.b64.txt"
    text.write_text(base64.encodebytes(raw).decode())
    assert base64.decodebytes(text.read_bytes()) == raw, "base64 copy does not decode to the bundle"
    sha = hashlib.sha256(raw).hexdigest()
    heads = git("bundle", "list-heads", str(bundle))
    count = git("rev-list", "--count", f"{remote}..HEAD") if have else "all"
    readme = dest / f"mml-{stamp}-README.txt"
    readme.write_text(
        f"My Medieval Life: off-machine backup {stamp}\n\n"
        f"Bundle file: {text.name} (base64 of a git bundle)\nsha256 of the decoded bundle: {sha}\n"
        f"Bundle size: {len(raw)} bytes\nBuilds on (already on GitHub): {have or 'nothing: full history'}\n"
        f"Commits not on GitHub: {count}\n\nRefs in the bundle:\n{heads}\n\n"
        "Restore:\n"
        f"  base64 -d {text.name} > mml.bundle && sha256sum mml.bundle   # must match the sha256 above\n"
        "  git clone https://github.com/verbal76/My-Medieval-Life restored && cd restored\n"
        f"  git fetch origin {branch}\n"
        "  git fetch ../mml.bundle 'refs/heads/*:refs/heads/*' 'refs/backup/*:refs/backup/*'\n"
        f"  git checkout {branch}\n"
        "  git diff <snapshot>^ <snapshot> | git apply   # an agent's or the checkout's uncommitted work\n")
    return [bundle, text, readme]


def main(argv):
    if "--push" in argv:
        wip = argv[argv.index("--wip") + 1].split(",") if "--wip" in argv else []
        for name, sha, ref in push([w for w in wip if w]):
            print(f"pushed {name} {sha[:7]} -> {ref} (remote hash checked)")
        return
    if "--offsite" in argv:
        for p in offsite(Path(argv[argv.index("--offsite") + 1])):
            print(f"saved {p} ({p.stat().st_size} bytes)")
        print("verified: the bundle verifies and its base64 copy decodes back to it; now upload the .txt files and test a restore")
        return
    dest = Path(argv[argv.index("--dir") + 1]) if "--dir" in argv else Path.home() / "mml-backups"
    saved = checkpoint(dest)
    keep = int(argv[argv.index("--keep") + 1]) if "--keep" in argv else 5
    stamps = sorted({p.name[4:19] for p in dest.glob("mml-*.bundle")})
    for old in stamps[:-keep]:
        for p in dest.glob(f"mml-{old}*"):
            p.unlink()
    for p in saved:
        print(f"saved {p} ({p.stat().st_size} bytes)")
    print(f"verified: bundle restores, every tree's commit is in it, every patch applies ({len(worktrees())} trees)")


if __name__ == "__main__":
    main(sys.argv[1:])
