"""Generated progress views of the requirements register (owner directive 2026-10-23,
docs/directives/2026-10-23_master_requirements_reconciliation.md, sections 11 and 15).

Every file in docs/requirements/views/ is generated from docs/requirements/requirements.json and is never edited by
hand. `python3 tools/check_requirements.py --write` writes them; the validator fails when one is out of date.

Counting rules: approved, in-scope requirements only (umbrellas, deferred, superseded, rejected, proposals and ideas
are listed but never counted); each record counted once; implementation, verification and release are separate
counts, never averaged; effort bands only where recorded, otherwise UNKNOWN.

    python3 tools/requirements_report.py            # print the status summary
"""
import json
import sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import check_requirements as cr  # noqa: E402

VIEWS = REPO / "docs" / "requirements" / "views"
BUILDS = ["18", "19", "20", "21"]
HEAD = ("Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. "
        "Do not edit: change the register (`tools/requirements_update.py`) and regenerate.")
OPEN_DISP = ("OPEN", "REOPENED", "PROVISIONAL")


def _c(s):
    return cr._cell(s if s is not None else "")


def scoped(d, b):
    return [r for r in d["requirements"] if r.get("target_build") == b and cr.in_scope(r)]


def decisions_for(d, b):
    return [r for r in d["requirements"] if r["kind"] == "decision" and r.get("target_build") == b and r.get("disposition") in OPEN_DISP]


def affected(d, did):
    return sorted(r["id"] for r in d["requirements"] if did in (r.get("decisions") or []) or did in (r.get("depends_on") or [])
                  or r.get("parent") == did or did in (r.get("related") or []))


def metrics(d, b):
    rs = scoped(d, b)
    im = Counter(r.get("implementation_status") for r in rs)
    ve = Counter(r.get("verification_status") for r in rs)
    de = Counter(r.get("design") or "UNKNOWN" for r in rs)
    op = [r for r in rs if r.get("completion") == "OPEN"]
    eff = Counter(r.get("effort") or "UNKNOWN" for r in op if r.get("implementation_status") != "INTEGRATED")
    dec = decisions_for(d, b)
    deferred = [r for r in d["requirements"] if r.get("target_build") == b and r["kind"] == "approved" and r.get("approval_status") == "DEFERRED"]
    lvl = lambda r: cr.VERIFIED_LEVEL.get(r.get("verification_status"), -1)
    return {
        "total": len(rs), "design": de, "impl": im, "ver": ve, "open": op, "effort": eff, "decisions": dec,
        "blocking_decisions": [x for x in dec if x.get("blocks_implementation")], "deferred": deferred,
        "integrated": sum(1 for r in rs if r.get("implementation_status") == "INTEGRATED"),
        "tested": sum(1 for r in rs if lvl(r) >= cr.VERIFIED_LEVEL["TARGETED TESTS PASSED"]),
        "integration_verified": sum(1 for r in rs if lvl(r) >= cr.VERIFIED_LEVEL["INTEGRATION VERIFIED"]),
        "gameplay": sum(1 for r in rs if lvl(r) >= cr.VERIFIED_LEVEL["GAMEPLAY VERIFIED"]),
        "owner": sum(1 for r in rs if r.get("verification_status") == "OWNER PLAYTESTED"),
        "complete": sum(1 for r in rs if r.get("completion") == "COMPLETE"),
        "proposals": [r for r in d["requirements"] if r.get("target_build") == b and r["kind"] in ("proposal", "idea") and cr.is_open(r)],
        "umbrellas": [r for r in d["requirements"] if r.get("target_build") == b and r.get("umbrella")],
    }


def readiness(d, b, m):
    info = (d.get("builds") or cr.BUILDS_DEFAULT).get(b, {})
    if info.get("released"):
        return "RELEASED (%s)" % info["released"]
    if not info.get("implementation_authorized"):
        return "NOT AUTHORIZED for implementation"
    if m["total"] and m["complete"] == m["total"]:
        return "RELEASE READY"
    gate = [r for r in scoped(d, b) if r.get("workstream") == "release gate"]
    work = [r for r in scoped(d, b) if r.get("workstream") != "release gate"]
    if work and all(r.get("completion") == "COMPLETE" or r.get("implementation_status") == "INTEGRATED" and
                    cr.VERIFIED_LEVEL.get(r.get("verification_status"), -1) >= cr.VERIFIED_LEVEL["INTEGRATION VERIFIED"] for r in work):
        return "RELEASE CANDIDATE (release gate open)" if gate else "RELEASE CANDIDATE"
    started = sum(1 for r in scoped(d, b) if r.get("implementation_status") not in ("NOT STARTED", "READY"))
    if b == "19" and not any("Build 18" in str(x) or "Build 19" in str(x) for r in scoped(d, b) for x in (r.get("integrated_in") or [])):
        return "PROTOTYPE ONLY (isolated branch; not integrated)" if started else "NOT STARTED"
    return "IN DEVELOPMENT (not feature complete)" if started else "NOT STARTED"


def pct(n, t):
    return "%d of %d (%d%%)" % (n, t, round(100.0 * n / t)) if t else "0 of 0"


def scorecard(d):
    ms = {b: metrics(d, b) for b in BUILDS}
    rows = [("Approved requirements (in scope)", lambda b, m: str(m["total"])),
            ("Fully specified (design SPECIFIED)", lambda b, m: pct(m["design"].get("SPECIFIED", 0), m["total"])),
            ("Waiting on an owner decision (design)", lambda b, m: str(m["design"].get("OWNER DECISION REQUIRED", 0))),
            ("Design work still required", lambda b, m: str(m["design"].get("DESIGN WORK REQUIRED", 0) + m["design"].get("PARTIAL", 0))),
            ("Design unknown", lambda b, m: str(m["design"].get("UNKNOWN", 0))),
            ("Not started (incl. READY)", lambda b, m: str(m["impl"].get("NOT STARTED", 0) + m["impl"].get("READY", 0))),
            ("In development (worker assigned)", lambda b, m: str(m["impl"].get("IN DEVELOPMENT", 0))),
            ("Partially implemented", lambda b, m: str(m["impl"].get("PARTIALLY IMPLEMENTED", 0))),
            ("Implemented on a task branch", lambda b, m: str(m["impl"].get("IMPLEMENTED ON TASK BRANCH", 0))),
            ("Implementation blocked", lambda b, m: str(m["impl"].get("IMPLEMENTATION BLOCKED", 0))),
            ("Integrated", lambda b, m: pct(m["integrated"], m["total"])),
            ("Automated tests passed (targeted or better)", lambda b, m: pct(m["tested"], m["total"])),
            ("Integration verified (suite on the integrated build)", lambda b, m: pct(m["integration_verified"], m["total"])),
            ("Gameplay verified", lambda b, m: pct(m["gameplay"], m["total"])),
            ("Owner playtested", lambda b, m: pct(m["owner"], m["total"])),
            ("Complete", lambda b, m: pct(m["complete"], m["total"])),
            ("Release blockers (open in-scope requirements)", lambda b, m: str(len(m["open"]))),
            ("Open owner decisions (of which blocking)", lambda b, m: "%d (%d)" % (len(m["decisions"]), len(m["blocking_decisions"]))),
            ("Deferred with approval", lambda b, m: str(len(m["deferred"]))),
            ("Proposals and ideas (not counted)", lambda b, m: str(len(m["proposals"]))),
            ("Integrated, awaiting gameplay or owner verification", lambda b, m: str(sum(1 for r in m["open"] if r.get("implementation_status") == "INTEGRATED"))),
            ("Remaining implementation by effort band (not yet integrated)", lambda b, m: ", ".join("%s %d" % (k, m["effort"][k]) for k in cr.EFFORT if m["effort"].get(k)) or "none"),
            ("Readiness", lambda b, m: readiness(d, b, m))]
    lines = ["| Measure | " + " | ".join("Build %s" % b for b in BUILDS) + " |", "|---|" + "---|" * len(BUILDS)]
    for name, f in rows:
        lines.append("| %s | %s |" % (name, " | ".join(f(b, ms[b]) for b in BUILDS)))
    return lines


def status_view(d):
    lines = ["# Requirements status by build", "", HEAD, "",
             "Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella "
             "entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification "
             "and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates "
             "where recorded; UNKNOWN where not.", ""]
    lines += scorecard(d)
    lines += ["", "Build authority:", ""]
    for b in BUILDS:
        info = (d.get("builds") or cr.BUILDS_DEFAULT).get(b, {})
        lines.append("- **Build %s (%s):** implementation %s. %s" % (b, info.get("name", ""), "authorized" if info.get("implementation_authorized") else "**NOT AUTHORIZED**",
                                                                    info.get("authority", "")))
    back = [r for r in d["requirements"] if r.get("target_build") in ("20+", "unassigned", "owner decision") and cr.is_open(r)]
    lines += ["", "Future backlog and unassigned: %d open records (`BACKLOG.md`). Open owner decisions: %d (`DECISIONS.md`)." % (
        len(back), sum(1 for r in d["requirements"] if r["kind"] == "decision" and r.get("disposition") in OPEN_DISP)), ""]
    return "\n".join(lines) + "\n"


def build_view(d, b):
    m = metrics(d, b)
    info = (d.get("builds") or cr.BUILDS_DEFAULT).get(b, {})
    lines = ["# Build %s: %s" % (b, info.get("name", "")), "", HEAD, ""]
    if not info.get("implementation_authorized"):
        lines += ["> **Implementation of Build %s is NOT AUTHORIZED.** %s Nothing below is implemented work." % (b, info.get("authority", "")), ""]
    else:
        lines += ["Authority: %s" % (info.get("authority") or "—"), ""]
    lines += ["Readiness: **%s**" % readiness(d, b, m), "",
              "| Count | Value |", "|---|---|",
              "| Approved requirements in scope | %d |" % m["total"],
              "| Integrated | %s |" % pct(m["integrated"], m["total"]),
              "| Automated tests passed | %s |" % pct(m["tested"], m["total"]),
              "| Integration verified | %s |" % pct(m["integration_verified"], m["total"]),
              "| Gameplay verified | %s |" % pct(m["gameplay"], m["total"]),
              "| Owner playtested | %s |" % pct(m["owner"], m["total"]),
              "| Complete | %s |" % pct(m["complete"], m["total"]),
              "| Open (release blockers) | %d |" % len(m["open"]),
              "| Open owner decisions (blocking) | %d (%d) |" % (len(m["decisions"]), len(m["blocking_decisions"])), ""]
    rs = scoped(d, b)
    by = {r["id"]: r for r in d["requirements"]}
    open_dec = {x["id"] for x in d["requirements"] if x["kind"] == "decision" and x.get("disposition") in OPEN_DISP}

    def blockers(r):
        if r.get("implementation_status") == "INTEGRATED":
            return []
        out = [x for x in (r.get("decisions") or []) if x in open_dec]
        out += [x for x in (r.get("depends_on") or []) if x in by and cr.is_open(by[x]) and by[x].get("implementation_status") != "INTEGRATED"]
        if r.get("design") in ("OWNER DECISION REQUIRED", "DESIGN WORK REQUIRED", "UNKNOWN", None) and r.get("implementation_status") != "INTEGRATED":
            out.append("design: %s" % (r.get("design") or "UNKNOWN"))
        return out

    def code(r):
        if r.get("integrated_in"):
            return "; ".join(r["integrated_in"])
        if r.get("branch"):
            return r["branch"] + (" @ " + ", ".join(r.get("commits") or []) if r.get("commits") else "")
        return ", ".join(r.get("commits") or []) or "none"

    groups = [("In development (worker assigned)", lambda r: r.get("implementation_status") == "IN DEVELOPMENT"),
              ("Integrated, awaiting gameplay or owner verification", lambda r: r.get("implementation_status") == "INTEGRATED"),
              ("Ready to proceed now (approved, specified, nothing open blocks it)", lambda r: not blockers(r)),
              ("Blocked (open owner decision, unfinished dependency or unsettled design)", lambda r: bool(blockers(r)))]
    left = sorted([r for r in rs if r.get("completion") == "OPEN"], key=lambda r: r["id"])
    for title, test in groups:
        rows = [r for r in left if test(r)]
        left = [r for r in left if r not in rows]
        if not rows:
            continue
        lines += ["## %s (%d)" % (title, len(rows)), "",
                  "| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |",
                  "|---|---|---|---|---|---|---|---|---|"]
        for r in rows:
            wb = " / ".join(x for x in (r.get("assigned_worker"), r.get("branch")) if x)
            lines.append("| %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (
                r["id"], _c(r["title"]), r.get("approval_status"), r.get("implementation_status"),
                _c(code(r) if (r.get("integrated_in") or not wb) else wb), r.get("verification_status"),
                _c("; ".join(x for x in [r.get("remaining_work") or r.get("next_action") or "", ("known: " + "; ".join(r["known_defects"])) if r.get("known_defects") else ""] if x)),
                _c(", ".join(blockers(r))), "verification only" if r.get("implementation_status") == "INTEGRATED" else (r.get("effort") or "UNKNOWN")))
        lines.append("")
    done = sorted([r for r in rs if r.get("completion") == "COMPLETE"], key=lambda r: r["id"])
    if done:
        lines += ["## Complete (%d)" % len(done), "", "| ID | Requirement | Verification | Release |", "|---|---|---|---|"]
        lines += ["| %s | %s | %s | %s |" % (r["id"], _c(r["title"]), r.get("verification_status"), r.get("release_status")) for r in done]
        lines.append("")
    if m["decisions"]:
        lines += ["## Open owner decisions (%d)" % len(m["decisions"]), "", "| ID | Question | Disposition | Blocks | Affects |", "|---|---|---|---|---|"]
        for x in sorted(m["decisions"], key=lambda r: r["id"]):
            lines.append("| %s | %s | %s | %s | %s |" % (x["id"], _c(x["title"]), x.get("disposition"), "yes" if x.get("blocks_implementation") else "no",
                                                      ", ".join(affected(d, x["id"]))))
        lines.append("")
    other = sorted(m["umbrellas"] + m["proposals"] + m["deferred"], key=lambda r: r["id"])
    if other:
        lines += ["## Not counted: umbrellas, proposals, ideas, deferred (%d)" % len(other), "", "| ID | Item | Kind | Approval |", "|---|---|---|---|"]
        lines += ["| %s | %s | %s | %s |" % (r["id"], _c(r["title"]), "umbrella" if r.get("umbrella") else r["kind"], r.get("approval_status")) for r in other]
        lines.append("")
    return "\n".join(lines) + "\n"


def decisions_view(d):
    rows = [r for r in d["requirements"] if r["kind"] == "decision"]
    lines = ["# Owner decisions", "", HEAD, "",
             "The decision register is the `decision` records of the register. A recommendation is never an approval; "
             "PROVISIONAL is not final; an approved decision states design intent and may be revisited by the owner when "
             "evidence shows unintended consequences (SCHEMA.md, change control).", "",
             "| Disposition | Count |", "|---|---|"]
    c = Counter(r.get("disposition") for r in rows)
    lines += ["| %s | %d |" % (k, c.get(k, 0)) for k in cr.DISPOSITION] + [""]
    for t in cr.TARGETS:
        op = sorted([r for r in rows if r.get("target_build") == t and r.get("disposition") in OPEN_DISP], key=lambda r: r["id"])
        if not op:
            continue
        lines += ["## %s: open, reopened or provisional (%d)" % (cr.TARGET_NAMES.get(t, t), len(op)), "",
                  "| ID | Question | Disposition | Blocks implementation | Affects | Source |", "|---|---|---|---|---|---|"]
        for r in op:
            lines.append("| %s | %s | %s | %s | %s | %s |" % (r["id"], _c(r["title"]), r.get("disposition"), "yes" if r.get("blocks_implementation") else "no",
                                                          ", ".join(affected(d, r["id"])), _c(r.get("source"))))
        lines.append("")
    return "\n".join(lines) + "\n"


def backlog_view(d):
    lines = ["# Future backlog and unassigned work", "", HEAD, "",
             "Open records not assigned to Builds 18-21: the owner's \"Build 20 or later\" backlog, approved work with no build, "
             "work waiting on an owner decision for its build, and proposals and ideas. Nothing here is assigned to Build 20 "
             "or 21 until the owner says so.", ""]
    groups = [("20+", "Build 20 or later (backlog)"), ("unassigned", "Approved, no build assigned"),
              ("owner decision", "Waiting on an owner decision for its build"), ("owner action", "Owner or external action"),
              ("multiplayer", "Multiplayer track")]
    for t, name in groups:
        rows = sorted([r for r in d["requirements"] if r.get("target_build") == t and cr.is_open(r) and r["kind"] != "decision"], key=lambda r: r["id"])
        if not rows:
            continue
        lines += ["## %s (%d)" % (name, len(rows)), "", "| ID | Item | Kind | Approval | Implementation |", "|---|---|---|---|---|"]
        lines += ["| %s | %s | %s | %s | %s |" % (r["id"], _c(r["title"]), r["kind"], r.get("approval_status"), r.get("implementation_status")) for r in rows]
        lines.append("")
    return "\n".join(lines) + "\n"


def queues_view(d):
    rs = [r for r in d["requirements"] if r["kind"] == "approved" and cr.is_open(r) and not r.get("umbrella")]
    work = sorted([r for r in rs if r.get("implementation_status") in ("IN DEVELOPMENT", "IMPLEMENTED ON TASK BRANCH")], key=lambda r: r["id"])
    untested = sorted([r for r in rs if r.get("implementation_status") in ("INTEGRATED", "IMPLEMENTED ON TASK BRANCH", "PARTIALLY IMPLEMENTED")
                       and r.get("verification_status") == "NOT TESTED"], key=lambda r: r["id"])
    play = sorted([r for r in rs if r.get("playtest") and not r.get("playtest_done") and r.get("implementation_status") == "INTEGRATED"], key=lambda r: r["id"])
    lines = ["# Work queues", "", HEAD, "",
             "## Workers and task branches (%d)" % len(work), "", "| ID | Build | Status | Worker | Branch |", "|---|---|---|---|---|"]
    lines += ["| %s | %s | %s | %s | %s |" % (r["id"], r.get("target_build"), r.get("implementation_status"), _c(r.get("assigned_worker") or "none"), r.get("branch") or "") for r in work]
    lines += ["", "## Implemented but not tested (%d)" % len(untested), "", "| ID | Build | Implementation | Remaining |", "|---|---|---|---|"]
    lines += ["| %s | %s | %s | %s |" % (r["id"], r.get("target_build"), r.get("implementation_status"), _c(r.get("remaining_work") or "")) for r in untested]
    lines += ["", "## Awaiting owner playtest or device check (%d)" % len(play), "", "| ID | Build | Verification | Needs |", "|---|---|---|---|"]
    lines += ["| %s | %s | %s | %s |" % (r["id"], r.get("target_build"), r.get("verification_status"), _c(", ".join(r.get("playtest") or []))) for r in play]
    return "\n".join(lines) + "\n"


def views(d):
    out = {VIEWS / "STATUS.md": status_view(d), VIEWS / "DECISIONS.md": decisions_view(d),
           VIEWS / "BACKLOG.md": backlog_view(d), VIEWS / "QUEUES.md": queues_view(d)}
    for b in BUILDS:
        out[VIEWS / ("BUILD_%s.md" % b)] = build_view(d, b)
    return out


if __name__ == "__main__":
    print(status_view(cr.load((REPO / cr.REGISTER).read_text())))
