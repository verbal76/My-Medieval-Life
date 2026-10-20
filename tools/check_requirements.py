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
  - documents named in sources exist; the roadmap's anchor entries (ROAD-01, EQ-16, EXP-A/B/C, SJD-Q01..Q14) exist
    and each expansion names its specification; an open entry carries a target build; an owner decision leaves
    BLOCKED only with the owner's answer;
  - every frozen baseline (docs/requirements/baseline_*.json, MEM-02): each of its entries is still in the register and
    any change since carries a new history entry; its reconciliation report is regenerated with --write;
  - the project memory (MEM-01): docs/PROJECT_MEMORY.md and docs/CURRENT_DEVELOPMENT_STATE.md exist, every path they
    name exists, and the state file names every entry in ACTIVE DEVELOPMENT;
  - with --against REF: every id in the register at REF is still present (ids are never deleted or recycled), and
    every status change or change of target build since REF has a new history entry saying why; an owner
    decision never turns into another kind without the owner's answer. A register moved to a new path is found
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
DOC_RE = re.compile(r"\b((?:docs|tools|game|tests)/[\w./-]+\.(?:md|json|py|gd|cfg|pdf|txt))")
## The project memory (MEM-01, owner 2026-10-20): the entry point and the session handoff, checked with the register.
MEMORY = REPO / "docs" / "PROJECT_MEMORY.md"
STATE = REPO / "docs" / "CURRENT_DEVELOPMENT_STATE.md"
## Entries the roadmap rests on: they must stay in the register, and an expansion's specification must exist.
ANCHORS = ["ROAD-01", "EQ-16", "EXP-A", "EXP-B", "EXP-C"] + ["SJD-Q%02d" % i for i in range(1, 15)]
LINK_RE = re.compile(r"`((?:docs|tools|game|tests|\.github|\.claude)/[^`*\s]+|CLAUDE\.md)`")


def load(text):
    d = json.loads(text)
    if d.get("format") != "mml-requirements/1":
        raise ValueError("not an mml-requirements/1 register")
    return d


## The owner's five-build roadmap (ROAD-01, 2026-10-20): every open entry names where it goes.
TARGETS = ["15", "16", "17", "18", "19", "20+", "multiplayer", "owner decision", "owner action"]
TARGET_NAMES = {"15": "Build 15: simulation stabilization", "16": "Build 16: long-term equilibrium and validation",
                "17": "Build 17: Mining & Industrial Development", "18": "Build 18: Settlement Advancement & Regional Economy",
                "19": "Build 19: NPC Judgment System", "20+": "Build 20 or later (outside the five builds)",
                "multiplayer": "Multiplayer track (isolated branch)", "owner decision": "Waiting on an owner decision",
                "owner action": "Owner or external action (not development work)"}


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
        if r.get("kind") != "rule" and r.get("status") not in CLOSED and r.get("target_build") not in TARGETS:
            errors.append("%s: open entry without a roadmap target (target_build one of %s)" % (rid, ", ".join(TARGETS)))
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
        # an owner decision is resolved only by the owner's words (MEM-01): without them it stays BLOCKED
        if r.get("kind") == "decision" and r.get("status") != "BLOCKED" and not (
                str(r.get("owner_wording") or "").strip() or str(r.get("owner_answer") or "").strip()):
            errors.append("%s: an open owner decision cannot leave BLOCKED without the owner's answer (owner_answer)" % rid)
        if (r.get("kind") == "decision" and r.get("status") == "BLOCKED" and r.get("target_build") in TARGETS[:6]
                and r.get("roadmap_gate") != "owner decision first"):
            errors.append("%s: an open owner decision placed in a build needs the gate 'owner decision first'" % rid)
        if r.get("status") == "CANCELED BY OWNER" and not str(r.get("canceled_by_owner") or "").strip():
            errors.append("%s: CANCELED BY OWNER must cite the owner's cancellation (canceled_by_owner)" % rid)
        if r.get("status") == "COMPLETE AND VERIFIED" and r.get("kind") == "approved":
            if not (str(r.get("implementation") or "").strip() or str(r.get("tests") or "").strip() or r.get("commits")):
                errors.append("%s: COMPLETE AND VERIFIED without implementation, test or commit evidence" % rid)
            if r.get("playtest") and not r.get("playtest_done"):
                errors.append("%s: COMPLETE AND VERIFIED with an open playtest requirement %s" % (rid, r["playtest"]))
        if check_docs:                       # every field but the history (which may name files since retired)
            for f in sorted(k for k in r if k != "history"):
                for m in DOC_RE.findall(json.dumps(r[f], ensure_ascii=False)):
                    if not (REPO / m).exists():
                        errors.append("%s: %s names %s, which does not exist" % (rid, f, m))
    for a in ANCHORS:
        if a not in by_id:
            errors.append("%s: the roadmap names it, but it is not in the register" % a)
        elif a.startswith("EXP-") and not DOC_RE.search(str(by_id[a].get("source") or "")):
            errors.append("%s: an expansion must name its specification document in its source" % a)
    if check_docs:
        errors += memory_errors(d)
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


## The memory files (MEM-01): both exist; every repository path they name exists; the handoff names every
## requirement in ACTIVE DEVELOPMENT, so a new session sees all work in progress.
def memory_errors(d):
    errors = []
    for f in (MEMORY, STATE):
        if not f.exists():
            errors.append("%s is missing (the project memory, MEM-01)" % f.relative_to(REPO))
            continue
        for m in sorted(set(LINK_RE.findall(f.read_text()))):
            path = m.rstrip("/.,;:)")
            generated = {str(reconciliation_path(bp).relative_to(REPO)) for bp in BASELINES}   # written by --write
            if not (REPO / path).exists() and not list(REPO.glob(path)) and path not in generated:
                errors.append("%s names %s, which does not exist" % (f.relative_to(REPO), path))
    if STATE.exists():
        text = STATE.read_text()
        for r in d.get("requirements", []):
            if r.get("status") == "ACTIVE DEVELOPMENT" and not re.search(r"\b%s\b" % re.escape(r["id"]), text):
                errors.append("%s is in ACTIVE DEVELOPMENT but docs/CURRENT_DEVELOPMENT_STATE.md does not mention it" % r["id"])
    return errors


## Frozen baselines (MEM-02, owner 2026-10-20): docs/requirements/baseline_<date>.json records every open entry and
## every closed approved entry at a reconciliation. Each must stay in the register, and any change to its status, kind
## or target build since then must come with a new history entry. The reconciliation report is generated from it.
BASELINES = sorted((REPO / "docs" / "requirements").glob("baseline_*.json"))


def baseline_errors(d, b):
    errors = []
    by = {r["id"]: r for r in d.get("requirements", [])}
    for group in ("open", "closed_approved"):
        for rid, was in sorted(b.get(group, {}).items()):
            r = by.get(rid)
            if r is None:
                errors.append("%s: in the %s baseline (%s), now missing from the register" % (rid, b.get("date"), group))
                continue
            changed = any(was.get(k) is not None and was.get(k) != r.get(k) for k in ("status", "kind", "target_build"))
            if changed and len(r.get("history") or []) <= was.get("history", 0):
                errors.append("%s: changed since the %s baseline (%s, build %s -> %s, build %s) with no history entry saying why" % (
                    rid, b.get("date"), was.get("status"), was.get("target_build"), r.get("status"), r.get("target_build")))
    return errors


def reconciliation_path(bpath):
    return bpath.parent / ("RECONCILIATION_%s.md" % bpath.stem.split("_", 1)[1])


def render_reconciliation(d, b):
    by = {r["id"]: r for r in d["requirements"]}
    op, cl = b["open"], b["closed_approved"]
    now_closed = [i for i in op if by.get(i, {}).get("status") in CLOSED]
    moved = [i for i in op if i in by and by[i].get("target_build") != op[i].get("target_build")]
    reopened = [i for i in cl if i in by and by[i]["status"] not in CLOSED]
    new = [r for r in d["requirements"] if r["id"] not in op and r["id"] not in cl and r["kind"] != "rule"]
    lines = ["# Requirements reconciliation of %s (baseline `%s`)" % (b["date"], b["commit"]), "",
             "Generated by `python3 tools/check_requirements.py --write` from the frozen baseline",
             "`docs/requirements/%s` and the current register; do not edit. The baseline is the owner-reviewed" % ("baseline_%s.json" % b["date"]),
             "reconciliation of every open entry against the five-build roadmap (ROAD-01). The validator fails if any baseline",
             "entry leaves the register or changes without a history entry.", "",
             "| | Baseline | Now |", "|---|---|---|",
             "| Open entries (rules excluded) | %d | %d still open, %d closed since |" % (len(op), len(op) - len(now_closed), len(now_closed)),
             "| Closed approved (complete, superseded, canceled) | %d | %d still closed, %d reopened |" % (len(cl), len(cl) - len(reopened), len(reopened)),
             "| Entries added since (rules excluded) | | %d |" % len(new),
             "| Open entries moved to another build | | %d |" % len(moved), ""]
    def table(title, ids, extra=None):
        out = ["## %s (%d)" % (title, len(ids)), ""]
        if not ids:
            return out + ["None.", ""]
        out += ["| ID | Item | Kind | Baseline status | Baseline build | Status now | Build now | Last history |", "|---|---|---|---|---|---|---|---|"]
        for i in sorted(ids):
            r, was = by[i], (op.get(i) or cl.get(i))
            last = (r.get("history") or [{}])[-1]
            out.append("| %s | %s | %s | %s | %s | %s | %s | %s |" % (i, _cell(r["title"]), r["kind"], was.get("status"), was.get("target_build") or "",
                       r["status"], r.get("target_build") or "", _cell("%s: %s" % (last.get("date", ""), last.get("why") or last.get("change") or ""))))
        return out + [""]
    lines += table("Closed since the baseline", now_closed)
    lines += table("Moved to another build since the baseline", moved)
    lines += table("Reopened since the baseline", reopened)
    lines += ["## Added since the baseline (%d)" % len(new), "", "| ID | Item | Kind | Status | Build |", "|---|---|---|---|---|"]
    lines += ["| %s | %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), r["kind"], r["status"], r.get("target_build") or "") for r in sorted(new, key=lambda r: r["id"])]
    lines += ["", "The full, current list of open entries by build is the Roadmap section of `docs/DEVELOPMENT_LEDGER.md`.", ""]
    return "\n".join(lines)


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
        grew = len(n.get("history") or []) > len(o.get("history") or [])
        if o.get("target_build") and o.get("target_build") != n.get("target_build") and not grew:
            errors.append("%s: moved from build %s to %s with no new history entry saying why" % (
                o["id"], o.get("target_build"), n.get("target_build")))
        if o.get("kind") == "decision" and n.get("kind") != "decision" and not str(n.get("owner_answer") or "").strip():
            errors.append("%s: an owner decision became %s without the owner's answer (owner_answer)" % (o["id"], n.get("kind")))
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
             "rules are listed separately and are not counted as approved work. The order of work is in",
             "`docs/CURRENT_DEVELOPMENT_STATE.md` (start from `docs/PROJECT_MEMORY.md`);",
             "the ledger before this register is kept in `docs/requirements/LEDGER_ARCHIVE_2026-10-19.md`.", "",
             "## Counts (approved requirements; each counted once, by lifecycle status)", "",
             "| Status | Count |", "|---|---|"]
    for s in LIFECYCLE:
        lines.append("| %s | %d |" % (s, c.get(s, 0)))
    lines += ["| **Total approved** | **%d** |" % len(approved), "| Outstanding (not complete, superseded or canceled) | %d |" % len(open_), ""]
    other = Counter(r["kind"] for r in reqs if r["kind"] != "approved")
    lines += ["Also in the register: " + ", ".join("%d %s" % (other[k], KINDS[k].lower()) for k in KINDS if other.get(k)) + ".", ""]
    lines += _roadmap(reqs)
    dev = [r for r in approved if r["status"] not in CLOSED and not r.get("playtest_done") and (
        r.get("playtest") or r["status"] == "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED")]
    lines += ["## Real-device verification queue", "", "Every open entry with a device check outstanding (a `playtest` need, or the status AUTOMATED TESTS PASSED —",
              "PLAYTEST REQUIRED). Automated tests do not count as device verification.", "",
              "| ID | Requirement | Needs | Status |", "|---|---|---|---|"]
    for r in sorted(dev, key=lambda r: r["id"]):
        lines.append("| %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), ", ".join(r.get("playtest") or []) or "a device check", r["status"]))
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
            title = KINDS[k] if k != "decision" else "Owner decisions, open and answered (open: %d, status BLOCKED)" % sum(
                1 for r in rows if r["status"] == "BLOCKED")
            lines += ["## %s (%d)" % (title, len(rows)), "", "| ID | Item | Status | Source |", "|---|---|---|---|"]
            for r in sorted(rows, key=lambda r: r["id"]):
                lines.append("| %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), r["status"], _cell(r["source"])))
            lines.append("")
    return "\n".join(lines)


## The roadmap section: open entries (every kind but rules) by target build, each with its gate and reason.
def _roadmap(reqs):
    open_all = [r for r in reqs if r["kind"] != "rule" and r["status"] not in CLOSED]
    by_t = Counter(r.get("target_build") for r in open_all)
    lines = ["## Roadmap (owner, 2026-10-20: ROAD-01)", "",
             "Every open entry (approved work, proposals, decisions; rules excluded) with the build it belongs to. A gate says what",
             "must happen first (a device check, an owner decision, art). Completed entries are not counted here.",
             "Open owner decisions that belong to a build's design (OD-*, SJD-Q*) are listed under that build with the gate",
             "\"owner decision first\"; \"Waiting on an owner decision\" holds the rest. Every open owner decision is",
             "status BLOCKED (the ledger's owner-decisions section lists them all).", "",
             "| Target | Open entries | of which approved work |", "|---|---|---|"]
    for t in TARGETS:
        lines.append("| %s | %d | %d |" % (TARGET_NAMES[t], by_t.get(t, 0), sum(1 for r in open_all if r.get("target_build") == t and r["kind"] == "approved")))
    lines += ["| **Total open** | **%d** | **%d** |" % (len(open_all), sum(1 for r in open_all if r["kind"] == "approved")), ""]
    for t in TARGETS:
        rows = sorted([r for r in open_all if r.get("target_build") == t], key=lambda r: r["id"])
        if not rows:
            continue
        lines += ["### %s (%d)" % (TARGET_NAMES[t], len(rows)), "", "| ID | Item | Kind | Status | Gate | Why here |", "|---|---|---|---|---|---|"]
        for r in rows:
            lines.append("| %s | %s | %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), r["kind"], r["status"],
                                                          _cell(r.get("roadmap_gate") or ""), _cell(r.get("roadmap_reason") or "")))
        lines.append("")
    return lines


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
    outputs = [(LEDGER, render(d) + "\n")]
    for bp in BASELINES:
        b = json.loads(bp.read_text())
        errors += baseline_errors(d, b)
        outputs.append((reconciliation_path(bp), render_reconciliation(d, b)))
    if a.write and not errors:
        for path, text in outputs:
            path.write_text(text)
    elif not errors:
        for path, text in outputs:
            if not path.exists() or path.read_text() != text:
                errors.append("%s is out of date: run python3 tools/check_requirements.py --write" % path.relative_to(REPO))
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
