"""Add or update an entry in the requirements register, always with a history line (CLAUDE.md section 9a).

    # a new owner request (capture it before working on it)
    python3 tools/requirements_update.py add NEW-ID "Title" --source "owner message 2026-10-19 ..." \\
        --approval "owner asked for it" --wording "the owner's exact words" --accept "criterion" --accept "criterion"
    # a status change or new evidence
    python3 tools/requirements_update.py set B14-07 --status "ACTIVE DEVELOPMENT" --why "started" \\
        [--commit abc1234] [--tests "home_test"] [--field next_action="..."] [--playtest-done "phone, 2026-10-20, Pixel 7"]

Then run `python3 tools/check_requirements.py --write`. The register is docs/requirements/requirements.json.
"""
import argparse
import datetime
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REG = REPO / "docs" / "requirements" / "requirements.json"
sys.path.insert(0, str(REPO / "tools"))
from check_requirements import LIFECYCLE, KINDS  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("add")
    a.add_argument("id")
    a.add_argument("title")
    a.add_argument("--kind", default="approved", choices=sorted(KINDS))
    a.add_argument("--status", default="APPROVED — NOT STARTED", choices=LIFECYCLE)
    a.add_argument("--source", required=True)
    a.add_argument("--approval", default="")
    a.add_argument("--wording", default=None)
    a.add_argument("--accept", action="append", default=[])
    a.add_argument("--depends", action="append", default=[])
    a.add_argument("--parent", default=None)
    s = sub.add_parser("set")
    s.add_argument("id")
    s.add_argument("--status", choices=LIFECYCLE)
    s.add_argument("--why", required=True)
    s.add_argument("--commit", action="append", default=[])
    s.add_argument("--tests")
    s.add_argument("--superseded-by")
    s.add_argument("--playtest-done")
    s.add_argument("--field", action="append", default=[], help="key=value for a text field")
    for p in (a, s):
        p.add_argument("--date", default=datetime.date.today().isoformat())
    args = ap.parse_args()
    d = json.loads(REG.read_text())
    by = {r["id"]: r for r in d["requirements"]}
    if args.cmd == "add":
        if args.id in by:
            sys.exit("%s is already in the register: use set" % args.id)
        d["requirements"].append({
            "id": args.id, "title": args.title, "kind": args.kind, "status": args.status, "owner_wording": args.wording,
            "description": args.title, "source": args.source, "approval": args.approval, "acceptance": args.accept,
            "implementation": "", "tests": "", "playtest": [], "branch": "", "commits": [], "parent": args.parent,
            "depends_on": args.depends, "blockers": [], "rules": [], "interactions": [], "wiki": [], "next_action": "",
            "priority": "", "workstream": "", "superseded_by": None, "notes": "",
            "history": [{"date": args.date, "change": "entered in the register", "why": args.source}]})
        d["requirements"].sort(key=lambda r: r["id"])
    else:
        r = by.get(args.id)
        if r is None:
            sys.exit("%s is not in the register" % args.id)
        change = []
        if args.status and args.status != r["status"]:
            change.append("%s -> %s" % (r["status"], args.status))
            r["status"] = args.status
        if args.superseded_by:
            r["superseded_by"] = args.superseded_by
            change.append("superseded by " + args.superseded_by)
        for c in args.commit:
            if c not in r["commits"]:
                r["commits"].append(c)
                change.append("commit " + c)
        if args.tests:
            r["tests"] = args.tests
            change.append("tests")
        if args.playtest_done:
            r["playtest_done"] = args.playtest_done
            change.append("device check recorded")
        for kv in args.field:
            k, v = kv.split("=", 1)
            r[k] = v
            change.append(k)
        r["history"].append({"date": args.date, "change": "; ".join(change) or "note", "why": args.why})
    REG.write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n")
    print("updated %s" % args.id)


if __name__ == "__main__":
    main()
