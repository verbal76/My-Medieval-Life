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
"""
import datetime
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


def main(argv):
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
