"""Validate the requirements register and detect silently lost requirements (owner directive 2026-10-19,
docs/directives/2026-10-19_build14_readiness_requirements_preservation.md, Parts II and VI).

The register is docs/requirements/requirements.json (mml-requirements/1), the one authoritative list of every
owner-approved requirement, proposal, decision and design rule. docs/DEVELOPMENT_LEDGER.md is generated from it.

Checks (any failure exits 1):
  - unique ids of the allowed shape; valid kind and lifecycle status; required fields (title, source, approval for an
    approved requirement, acceptance criteria, a history entry);
  - parent, depends_on and superseded_by name existing ids; SUPERSEDED has a successor and nothing else does;
    CANCELED BY OWNER cites the owner's cancellation;
  - COMPLETE AND VERIFIED carries evidence (implementation, tests or commits) and has no open playtest requirement;
  - documents named in sources exist;
  - with --against REF: every id in the register at REF is still present (ids are never deleted or recycled), and
    every status change since REF has a new history entry saying why. A register moved to a new path is found
    through its "previous_paths".

    python3 tools/check_requirements.py                 # validate
    python3 tools/check_requirements.py --write         # validate and regenerate docs/DEVELOPMENT_LEDGER.md
    python3 tools/check_requirements.py --against origin/staging/my-medieval-life   # also compare with a commit
"""
import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REGISTER = "docs/requirements/requirements.json"
LEDGER = REPO / "docs" / "DEVELOPMENT_LEDGER.md"
LIFECYCLE = ["APPROVED — NOT STARTED", "ACTIVE DEVELOPMENT", "PARTIALLY IMPLEMENTED", "IMPLEMENTED — TESTING REQUIRED",
             "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED", "BLOCKED", "DEFERRED", "COMPLETE AND VERIFIED", "SUPERSEDED",
             "CANCELED BY OWNER", "UNKNOWN — INVESTIGATION REQUIRED"]
CLOSED = {"COMPLETE AND VERIFIED", "SUPERSEDED", "CANCELED BY OWNER"}
KINDS = {"approved": "Approved requirement", "proposal": "Proposal awaiting an owner decision (not approved)",
         "decision": "Open owner decision", "rule": "World design rule", "idea": "Unapproved idea",
         "rejected": "Rejected proposal"}
ID_RE = re.compile(r"^[A-Z][A-Z0-9]*(-[A-Z0-9.]+)+$")
DOC_RE = re.compile(r"\b((?:docs|tools|game|tests)/[\w./-]+\.(?:md|json|py|gd|cfg))")


def load(text):
    d = json.loads(text)
    if d.get("format") != "mml-requirements/1":
        raise ValueError("not an mml-requirements/1 register")
    return d


def validate(d, check_docs=True):
    errors = []
    reqs = d.get("requirements", [])
    ids = [r.get("id") for r in reqs]
    by_id = {}
    for r in reqs:
        rid = r.get("id", "")
        if not ID_RE.match(rid):
            errors.append("%s: id is not of the form PREFIX-NUMBER" % rid)
        if rid in by_id:
            errors.append("%s: duplicate id" % rid)
        by_id[rid] = r
    for r in reqs:
        rid = r.get("id")
        if r.get("kind") not in KINDS:
            errors.append("%s: unknown kind %r" % (rid, r.get("kind")))
        if r.get("status") not in LIFECYCLE:
            errors.append("%s: unknown status %r" % (rid, r.get("status")))
        for f in ("title", "source"):
            if not str(r.get(f) or "").strip():
                errors.append("%s: no %s" % (rid, f))
        if r.get("kind") == "approved" and not str(r.get("approval") or "").strip():
            errors.append("%s: an approved requirement needs its approval evidence" % rid)
        if not r.get("acceptance"):
            errors.append("%s: no acceptance criteria" % rid)
        if not r.get("history"):
            errors.append("%s: no history (who entered it, when, why)" % rid)
        for f in ("depends_on",):
            for x in r.get(f) or []:
                if x not in by_id:
                    errors.append("%s: %s names %s, which is not in the register" % (rid, f, x))
        if r.get("parent") and r["parent"] not in by_id:
            errors.append("%s: parent %s is not in the register" % (rid, r["parent"]))
        sup = r.get("superseded_by")
        if r.get("status") == "SUPERSEDED":
            if not sup or sup not in by_id:
                errors.append("%s: SUPERSEDED needs superseded_by naming an existing requirement" % rid)
        elif sup:
            errors.append("%s: superseded_by is set but the status is %s" % (rid, r.get("status")))
        if r.get("status") == "CANCELED BY OWNER" and not str(r.get("canceled_by_owner") or "").strip():
            errors.append("%s: CANCELED BY OWNER must cite the owner's cancellation (canceled_by_owner)" % rid)
        if r.get("status") == "COMPLETE AND VERIFIED" and r.get("kind") == "approved":
            if not (str(r.get("implementation") or "").strip() or str(r.get("tests") or "").strip() or r.get("commits")):
                errors.append("%s: COMPLETE AND VERIFIED without implementation, test or commit evidence" % rid)
            if r.get("playtest") and not r.get("playtest_done"):
                errors.append("%s: COMPLETE AND VERIFIED with an open playtest requirement %s" % (rid, r["playtest"]))
        if check_docs:
            for m in DOC_RE.findall(str(r.get("source") or "")):
                if not (REPO / m).exists():
                    errors.append("%s: source names %s, which does not exist" % (rid, m))
    # parent chains must not loop
    for r in reqs:
        seen, p = set(), r.get("parent")
        while p:
            if p in seen:
                errors.append("%s: parent chain loops" % r["id"])
                break
            seen.add(p)
            p = by_id.get(p, {}).get("parent")
    return errors


def compare(old, new):
    """Requirements lost or changed without a record since `old` (both registers as dicts)."""
    errors = []
    new_by = {r["id"]: r for r in new.get("requirements", [])}
    for o in old.get("requirements", []):
        n = new_by.get(o["id"])
        if n is None:
            errors.append("%s (%s, %s) disappeared from the register: requirements are never deleted; close it as "
                          "COMPLETE AND VERIFIED, SUPERSEDED or CANCELED BY OWNER instead" % (o["id"], o.get("kind"), o.get("status")))
            continue
        changed = o.get("status") != n.get("status") or o.get("kind") != n.get("kind")
        if changed and len(n.get("history") or []) <= len(o.get("history") or []):
            errors.append("%s: %s -> %s with no new history entry saying why" % (o["id"], o.get("status"), n.get("status")))
        if len(n.get("history") or []) < len(o.get("history") or []):
            errors.append("%s: history entries were removed" % o["id"])
    return errors


def at_ref(ref, d):
    for path in [REGISTER] + list(d.get("previous_paths", [])):
        r = subprocess.run(["git", "-C", str(REPO), "show", "%s:%s" % (ref, path)], capture_output=True, text=True)
        if r.returncode == 0:
            return load(r.stdout)
    return None


def counts(d):
    c = Counter()
    for r in d["requirements"]:
        if r["kind"] == "approved":
            c[r["status"]] += 1
    return c


def render(d):
    reqs = d["requirements"]
    c = counts(d)
    approved = [r for r in reqs if r["kind"] == "approved"]
    open_ = [r for r in approved if r["status"] not in CLOSED]
    lines = ["# Development ledger: the requirements register", "",
             "Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`; do not edit",
             "this file. Every owner-approved requirement stays here until it is COMPLETE AND VERIFIED, SUPERSEDED by a named",
             "requirement, or CANCELED BY OWNER (CLAUDE.md, requirements register). Proposals, open owner decisions and design",
             "rules are listed separately and are not counted as approved work. The order of work is `docs/DEVELOPMENT_QUEUE.md`;",
             "the ledger before this register is kept in `docs/requirements/LEDGER_ARCHIVE_2026-10-19.md`.", "",
             "## Counts (approved requirements; each counted once, by lifecycle status)", "",
             "| Status | Count |", "|---|---|"]
    for s in LIFECYCLE:
        lines.append("| %s | %d |" % (s, c.get(s, 0)))
    lines += ["| **Total approved** | **%d** |" % len(approved), "| Outstanding (not complete, superseded or canceled) | %d |" % len(open_), ""]
    other = Counter(r["kind"] for r in reqs if r["kind"] != "approved")
    lines += ["Also in the register: " + ", ".join("%d %s" % (other[k], KINDS[k].lower()) for k in KINDS if other.get(k)) + ".", ""]
    dev = [r for r in approved if r.get("playtest") and not r.get("playtest_done")]
    lines += ["## Real-device verification queue", "", "Automated tests do not count as device verification.", "",
              "| ID | Requirement | Needs | Status |", "|---|---|---|---|"]
    for r in sorted(dev, key=lambda r: r["id"]):
        lines.append("| %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), ", ".join(r["playtest"]), r["status"]))
    lines.append("")
    for s in LIFECYCLE:
        rows = [r for r in approved if r["status"] == s]
        if not rows:
            continue
        lines += ["## %s (%d)" % (s, len(rows)), "", "| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |", "|---|---|---|---|---|---|"]
        for r in sorted(rows, key=lambda r: r["id"]):
            ev = "; ".join(x for x in [", ".join("`%s`" % c for c in r.get("commits") or []), r.get("tests") or "",
                                        ("branch " + r["branch"]) if r.get("branch") else ""] if x)
            blk = "; ".join((r.get("blockers") or []) + ["after " + x for x in r.get("depends_on") or []] +
                            (["superseded by " + r["superseded_by"]] if r.get("superseded_by") else []))
            lines.append("| %s | %s | %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), _cell(r["source"]), _cell(ev),
                                                            _cell(blk), _cell(r.get("next_action") or "")))
        lines.append("")
    for k in ("decision", "rule", "proposal", "idea", "rejected"):
        rows = [r for r in reqs if r["kind"] == k]
        if rows:
            lines += ["## %s (%d)" % (KINDS[k], len(rows)), "", "| ID | Item | Status | Source |", "|---|---|---|---|"]
            for r in sorted(rows, key=lambda r: r["id"]):
                lines.append("| %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), r["status"], _cell(r["source"])))
            lines.append("")
    return "\n".join(lines)


def _cell(s):
    return str(s).replace("|", "/").replace("\n", " ")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--write", action="store_true", help="regenerate docs/DEVELOPMENT_LEDGER.md")
    ap.add_argument("--against", metavar="REF", help="also check nothing was lost since this git commit or branch")
    ap.add_argument("--register", default=str(REPO / REGISTER), help=argparse.SUPPRESS)
    a = ap.parse_args()
    d = load(Path(a.register).read_text())
    errors = validate(d)
    if a.against:
        old = at_ref(a.against, d)
        if old is None:
            print("note: no register at %s to compare with" % a.against)
        else:
            errors += compare(old, d)
    if a.write and not errors:
        LEDGER.write_text(render(d) + "\n")
    elif not errors:
        if LEDGER.read_text() != render(d) + "\n":
            errors.append("docs/DEVELOPMENT_LEDGER.md is out of date: run python3 tools/check_requirements.py --write")
    for e in errors:
        print("problem:", e)
    c = counts(d)
    total = sum(c.values())
    approved = sum(1 for r in d["requirements"] if r["kind"] == "approved")
    if total != approved:
        print("problem: counts do not reconcile (%d by status, %d approved)" % (total, approved))
        errors.append("counts")
    print("%d entries, %d approved (%d outstanding), %d problems" % (len(d["requirements"]), approved,
          sum(n for s, n in c.items() if s not in CLOSED), len(errors)))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
