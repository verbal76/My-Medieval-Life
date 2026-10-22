"""Add or update a record in the requirements register, always with a history line (CLAUDE.md section 9a,
docs/requirements/SCHEMA.md). Run it on staging/my-medieval-life only: the register is edited nowhere else.

    # a new owner requirement (capture it before working on it)
    python3 tools/requirements_update.py add NEW-ID "Title" --source "docs/directives/..." \\
        --approval "owner, 2026-10-23" --wording "the owner's exact words" --accept "criterion" [--build 18|unassigned]
    # a new owner decision or open question
    python3 tools/requirements_update.py add-decision NEW-Q "Exact question" --source "..." --build 18 [--blocks]
    # progress, evidence, verification (dimensions are separate; set only what the evidence shows)
    python3 tools/requirements_update.py set B14-07 --why "started" --impl "IN DEVELOPMENT" --worker "x" --branch wip/x
    python3 tools/requirements_update.py set B14-07 --why "merged" --impl INTEGRATED --commit abc1234 --integrated "Build 18 wip/build18"
    python3 tools/requirements_update.py set B14-07 --why "suite passed on the merge" --verif "INTEGRATION VERIFIED" \\
        --tests "suite counts" --test-commit abc1234
    python3 tools/requirements_update.py set B14-07 --why "owner played it" --verif "OWNER PLAYTESTED" --playtest-done "phone, 2026-10-24"
    python3 tools/requirements_update.py set Q-1 --why "owner answered" --disposition APPROVED --field owner_answer="..."

Then run `python3 tools/check_requirements.py --write` and commit on staging.
"""
import argparse
import datetime
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REG = REPO / "docs" / "requirements" / "requirements.json"
sys.path.insert(0, str(REPO / "tools"))
import check_requirements as cr  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("add")
    a.add_argument("id")
    a.add_argument("title")
    a.add_argument("--kind", default="approved", choices=sorted(k for k in cr.KINDS if k != "decision"))
    a.add_argument("--source", required=True)
    a.add_argument("--approval", default="")
    a.add_argument("--wording", default=None)
    a.add_argument("--accept", action="append", default=[])
    a.add_argument("--depends", action="append", default=[])
    a.add_argument("--decision", action="append", default=[])
    a.add_argument("--parent", default=None)
    a.add_argument("--build", default="unassigned", choices=cr.TARGETS)
    q = sub.add_parser("add-decision")
    q.add_argument("id")
    q.add_argument("question")
    q.add_argument("--source", required=True)
    q.add_argument("--build", default="owner decision", choices=cr.TARGETS)
    q.add_argument("--blocks", action="store_true")
    q.add_argument("--related", action="append", default=[])
    s = sub.add_parser("set")
    s.add_argument("id")
    s.add_argument("--why", required=True)
    s.add_argument("--approval-status", choices=cr.APPROVAL)
    s.add_argument("--impl", choices=cr.IMPLEMENTATION)
    s.add_argument("--verif", choices=cr.VERIFICATION)
    s.add_argument("--release", choices=cr.RELEASE)
    s.add_argument("--completion", choices=cr.COMPLETION)
    s.add_argument("--disposition", choices=cr.DISPOSITION)
    s.add_argument("--build", choices=cr.TARGETS)
    s.add_argument("--worker")
    s.add_argument("--branch")
    s.add_argument("--commit", action="append", default=[])
    s.add_argument("--integrated", action="append", default=[])
    s.add_argument("--tests")
    s.add_argument("--test-commit")
    s.add_argument("--defect", action="append", default=[])
    s.add_argument("--superseded-by")
    s.add_argument("--playtest-done")
    s.add_argument("--field", action="append", default=[], help="key=value for a text field")
    for p in (a, q, s):
        p.add_argument("--date", default=datetime.date.today().isoformat())
    args = ap.parse_args()
    d = json.loads(REG.read_text())
    by = {r["id"]: r for r in d["requirements"]}
    if args.cmd in ("add", "add-decision") and args.id in by:
        sys.exit("%s is already in the register: use set" % args.id)
    if args.cmd == "add":
        approved = args.kind == "approved"
        d["requirements"].append({
            "id": args.id, "kind": args.kind, "title": args.title, "description": args.title, "source": args.source,
            "owner_wording": args.wording, "approval": args.approval, "acceptance": args.accept, "target_build": args.build,
            "parent": args.parent, "depends_on": args.depends, "decisions": args.decision,
            "approval_status": "OWNER APPROVED" if approved else ("REJECTED" if args.kind == "rejected" else "PROPOSED"),
            "implementation_status": "NOT STARTED", "verification_status": "NOT TESTED",
            "release_status": "NOT READY" if approved else "NOT APPLICABLE", "completion": "OPEN" if args.kind != "rejected" else "CLOSED",
            "history": [{"date": args.date, "change": "entered in the register", "why": args.source}]})
    elif args.cmd == "add-decision":
        d["requirements"].append({
            "id": args.id, "kind": "decision", "title": args.question, "description": args.question, "source": args.source,
            "owner_wording": None, "owner_answer": None, "disposition": "OPEN", "blocks_implementation": args.blocks,
            "target_build": args.build, "related": args.related, "approval": "", "acceptance": [],
            "history": [{"date": args.date, "change": "entered in the register", "why": args.source}]})
    else:
        r = by.get(args.id)
        if r is None:
            sys.exit("%s is not in the register" % args.id)
        change = []
        for key, val in (("approval_status", args.approval_status), ("implementation_status", args.impl),
                         ("verification_status", args.verif), ("release_status", args.release), ("completion", args.completion),
                         ("disposition", args.disposition), ("target_build", args.build), ("assigned_worker", args.worker),
                         ("branch", args.branch), ("tests", args.tests), ("test_commit", args.test_commit),
                         ("superseded_by", args.superseded_by), ("playtest_done", args.playtest_done)):
            if key == "tests" and val is not None and r.get("tests") and val not in str(r["tests"]):
                val = "%s; %s" % (r["tests"], val)        # evidence accumulates; a new run never erases an earlier one
            if val is not None and val != r.get(key):
                change.append("%s: %s -> %s" % (key, r.get(key), val))
                r[key] = val
        for key, vals in (("commits", args.commit), ("integrated_in", args.integrated), ("known_defects", args.defect)):
            for v in vals:
                if v not in (r.get(key) or []):
                    r.setdefault(key, []).append(v)
                    change.append("%s + %s" % (key, v))
        for kv in args.field:
            k, v = kv.split("=", 1)
            r[k] = [v] if k == "acceptance" else v     # acceptance is a list of criteria, never a bare string

            change.append(k)
        r.setdefault("history", []).append({"date": args.date, "change": "; ".join(change) or "note", "why": args.why})
    d["requirements"].sort(key=lambda r: r["id"])
    REG.write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n")
    print("updated %s" % args.id)


if __name__ == "__main__":
    main()
