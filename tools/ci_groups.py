"""Select the game suites of named subsystem groups (tools/ci_groups.json) from a tests.yml suite list.

Owner directive 2026-11-10 (docs/directives/2026-11-10_github_actions_testing.md): targeted Tests runs by subsystem.
    python3 tools/ci_groups.py LIST GROUP [GROUP ...]   # prints the matching suite lines of LIST, in order
A suite matches when its file name matches any regular expression of any named group. Unknown group names fail.
"""
import json
import os
import re
import sys


def select(lines, names, groups):
    bad = [n for n in names if n not in groups]
    if bad:
        raise SystemExit("unknown group(s): %s (known: %s)" % (" ".join(bad), " ".join(sorted(groups))))
    pats = [re.compile(p) for n in names for p in groups[n]]
    out = []
    for line in lines:
        t = line.strip()
        if t and not t.startswith("#") and any(p.search(t.split()[0].rsplit("/", 1)[-1]) for p in pats):
            out.append(line.rstrip("\n"))
    return out


def main(argv):
    if len(argv) < 3:
        raise SystemExit(__doc__)
    groups = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ci_groups.json")))["groups"]
    for line in select(open(argv[1]).readlines(), argv[2:], groups):
        print(line)


if __name__ == "__main__":
    main(sys.argv)
