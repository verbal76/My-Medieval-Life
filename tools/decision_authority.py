"""Decision authority and supersession safeguard (owner directive HAG-AUTH-01, 2026-11-09,
docs/directives/2026-11-09_decision_authority_supersession_safeguard.md).

Historical documentation must never be mistaken for current authority. This module gives every record in the one register
(docs/requirements/requirements.json; no second decision authority) an explicit lifecycle and checks that supersession and
current-authority directions are consistent. It is a library used by tools/check_requirements.py (validation and the generated
view docs/requirements/views/AUTHORITY.md) and tools/requirements_update.py (keeps `lifecycle` and the two-way links current).
It reads documents only; it never runs the game.

Lifecycle (the record's `lifecycle` field, derived from its status dimensions and checked to agree with them):
  SUPERSEDED   replaced; `superseded_by` names the replacement, which names it back in `supersedes`
  REJECTED     the owner rejected it
  DEFERRED     the owner deferred it
  UNDER REVIEW a proposal, idea or open owner question (decision OPEN or REOPENED; approval PROPOSED or OWNER DECISION REQUIRED)
  COMPLETED    an approved requirement whose implementation is COMPLETE against its acceptance criteria
  ACTIVE       governs now: an approved requirement not yet complete, an approved or provisional owner decision, a rule.
               A decision or rule stays ACTIVE after its implementation is done: completing the work does not retire the
               decision (directive point 6).

Checks (each is a problem for check_requirements):
  - `lifecycle` present and equal to the derived value;
  - supersession links two-way: A.superseded_by = B  <=>  A in B.supersedes; a record named in `supersedes` is SUPERSEDED;
  - chains end: following superseded_by never loops and ends at a record that is not REJECTED or DEFERRED (else the
    governing record is unclear and the owner or lead must resolve it);
  - conflicting active replacements: two records that are not SUPERSEDED both claim to supersede the same record;
  - current authority: the register's top-level `authority` block names the development line and records branch, and every
    entry point (CLAUDE.md, the state file, the recovery handoff, PROJECT_MEMORY) names both;
  - stale directions: a line in an entry point that presents a frozen branch as the current integration/development branch,
    without naming the current line or marking itself historical.

    python3 tools/decision_authority.py        # print the lifecycle counts and any problems
"""
import re
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIFECYCLES = ["ACTIVE", "SUPERSEDED", "COMPLETED", "REJECTED", "DEFERRED", "UNDER REVIEW"]
ENTRY_POINTS = ["CLAUDE.md", "docs/CURRENT_DEVELOPMENT_STATE.md", "docs/handoffs/CURRENT_SESSION_RECOVERY.md",
                "docs/PROJECT_MEMORY.md"]
CURRENT_WORDS = re.compile(r"(integration branch|development line|code integration|development branch|current development|"
                           r"code branch|develop on|the line is)", re.I)
HISTORICAL_WORDS = re.compile(r"(frozen|historical|history|formerly|until|was |were |stale|superseded|corrected|correction|"
                              r"older|old |no longer|moved|never resume|banner|copies|then `)", re.I)


def as_list(v):
    if not v:
        return []
    return [v] if isinstance(v, str) else list(v)


def lifecycle(r):
    """The record's lifecycle, derived from its status dimensions (see the module docstring)."""
    kind, ap, disp = r.get("kind"), r.get("approval_status"), r.get("disposition")
    if ap == "SUPERSEDED" or disp == "SUPERSEDED" or r.get("superseded_by"):
        return "SUPERSEDED"
    if ap == "REJECTED" or kind == "rejected":
        return "REJECTED"
    if ap == "DEFERRED" or disp == "DEFERRED":
        return "DEFERRED"
    if kind == "decision":
        return "ACTIVE" if disp in ("APPROVED", "PROVISIONAL") else "UNDER REVIEW"
    if ap in ("PROPOSED", "OWNER DECISION REQUIRED") or kind in ("proposal", "idea"):
        return "UNDER REVIEW"
    if kind == "approved" and r.get("completion") == "COMPLETE":
        return "COMPLETED"
    return "ACTIVE"


def governing(r, by_id):
    """The record that governs in r's place: r itself unless superseded, else the end of its superseded_by chain.
    Returns (record or None, chain of ids, problem or None)."""
    chain, cur = [r["id"]], r
    while cur.get("superseded_by"):
        nxt = cur["superseded_by"]
        if nxt in chain:
            return None, chain + [nxt], "supersession chain loops (%s)" % " -> ".join(chain + [nxt])
        if nxt not in by_id:
            return None, chain + [nxt], "superseded_by %s is not in the register" % nxt
        chain.append(nxt)
        cur = by_id[nxt]
    return cur, chain, None


def link_supersession(by_id, old_id, new_id, date, why):
    """Record `old_id` superseded by `new_id` in both directions (used by requirements_update)."""
    old, new = by_id[old_id], by_id[new_id]
    old["superseded_by"] = new_id
    sup = as_list(new.get("supersedes"))
    if old_id not in sup:
        new["supersedes"] = sup + [old_id]
        new.setdefault("history", []).append({"date": date, "change": "supersedes + %s" % old_id, "why": why})


def record_errors(d):
    errors = []
    reqs = d.get("requirements", [])
    by_id = {r.get("id"): r for r in reqs}
    claims = {}
    for r in reqs:
        rid = r.get("id")
        want = lifecycle(r)
        if r.get("lifecycle") not in LIFECYCLES:
            errors.append("%s: lifecycle %r is missing or unknown (HAG-AUTH-01; expected %s)" % (rid, r.get("lifecycle"), want))
        elif r["lifecycle"] != want:
            errors.append("%s: lifecycle %s disagrees with its status fields (they give %s)" % (rid, r["lifecycle"], want))
        target = r.get("superseded_by")
        if target and target in by_id and rid not in as_list(by_id[target].get("supersedes")):
            errors.append("%s: superseded_by %s, but %s does not name it in supersedes (one-way link)" % (rid, target, target))
        for old in as_list(r.get("supersedes")):
            if old not in by_id:
                errors.append("%s: supersedes %s, which is not in the register" % (rid, old))
                continue
            if by_id[old].get("superseded_by") != rid:
                errors.append("%s: supersedes %s, but %s is not marked superseded by it (superseded_by %s)"
                              % (rid, old, old, by_id[old].get("superseded_by")))
            if lifecycle(r) != "SUPERSEDED":
                claims.setdefault(old, []).append(rid)
        if target:
            head, chain, problem = governing(r, by_id)
            if problem:
                errors.append("%s: %s" % (rid, problem))
            elif lifecycle(head) in ("REJECTED", "DEFERRED"):
                errors.append("%s: its supersession chain ends at %s, which is %s: no record governs; resolve with the owner"
                              % (rid, head["id"], lifecycle(head)))
    for old, rids in sorted(claims.items()):
        if len(rids) > 1:
            errors.append("%s: conflicting active replacements %s both claim to supersede it; investigate, do not choose one"
                          % (old, ", ".join(sorted(rids))))
    return errors


def authority_block(d):
    return d.get("authority") or {}


def document_errors(d, repo=REPO):
    """Current-authority references and stale directions in the session entry points."""
    errors = []
    a = authority_block(d)
    by_id = {r.get("id"): r for r in d.get("requirements", [])}
    line, records, frozen = a.get("development_line"), a.get("records_branch"), as_list(a.get("frozen_branches"))
    if not line or not records:
        return ["register: the top-level authority block must name development_line and records_branch (HAG-AUTH-01)"]
    for rel in ENTRY_POINTS:
        p = repo / rel
        if not p.exists():
            errors.append("%s: entry point missing (HAG-AUTH-01)" % rel)
            continue
        text = p.read_text()
        for name, what in ((line, "development line"), (records, "records branch")):
            if "`%s`" % name not in text and name not in text:
                errors.append("%s: does not name the current %s %s (HAG-AUTH-01)" % (rel, what, name))
        historical_section = False
        for n, ln in enumerate(text.splitlines(), 1):
            if ln.startswith("## "):
                historical_section = "HISTORICAL" in ln
            elif re.search(r"(\*\*HISTORICAL|^> .*HISTORICAL)", ln):
                historical_section = True          # a section marked historical: its lines describe the past
            if historical_section or not CURRENT_WORDS.search(ln) or line in ln or HISTORICAL_WORDS.search(ln):
                continue
            exc = next((x for x in as_list(a.get("acknowledged_stale")) if x.get("file") == rel and x.get("contains", "\0") in ln), None)
            if exc:
                dec = by_id.get(exc.get("decision"))
                if dec is not None and lifecycle(dec) == "UNDER REVIEW":
                    continue                       # a known stale line the owner is deciding (listed in AUTHORITY.md)
                errors.append("%s:%d: acknowledged stale line's decision %s is no longer under review: correct the line"
                              % (rel, n, exc.get("decision")))
                continue
            for fb in frozen:
                if re.search(r"(?<![\w/-])%s(?![\w/-])" % re.escape(fb), ln):
                    errors.append("%s:%d: presents frozen branch %s as current; name %s or mark the line historical"
                                  % (rel, n, fb, line))
    return errors


def last_why(r, prefer=("SUPERSEDED", "superseded")):
    hist = r.get("history") or []
    for h in reversed(hist):
        if any(p in str(h.get("change", "")) for p in prefer):
            return str(h.get("why") or "")
    return str(hist[-1].get("why") or "") if hist else ""


def view(d, cell):
    """docs/requirements/views/AUTHORITY.md: what governs now, what was superseded and by what, what is under review."""
    reqs = sorted(d.get("requirements", []), key=lambda r: r["id"])
    by_id = {r["id"]: r for r in reqs}
    a = authority_block(d)
    head = ("Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write` "
            "(tools/decision_authority.py, HAG-AUTH-01). Do not edit.")
    c = Counter(lifecycle(r) for r in reqs)
    out = ["# Decision authority: what governs now", "", head, "",
           "Before any significant change, find its record here and follow `Governing record` to the decision in force. "
           "A document outside the register that disagrees with an ACTIVE record is historical unless the register says otherwise.",
           "", "## Current authority", "",
           "| | |", "|---|---|",
           "| Development line (code) | `%s` |" % a.get("development_line", "?"),
           "| Records branch | `%s` |" % a.get("records_branch", "?"),
           "| Frozen / historical branches (never resume work on them) | %s |" % ", ".join("`%s`" % b for b in as_list(a.get("frozen_branches"))),
           "| Set by | %s |" % cell(a.get("source", "")), ""]
    acks = as_list(a.get("acknowledged_stale"))
    if acks:
        out += ["Known stale lines kept while the owner decides (the checker accepts them only while the decision is under review):", "",
                "| File | Line text | Decision | Why |", "|---|---|---|---|"]
        out += ["| %s | %s | %s | %s |" % (x.get("file"), cell(x.get("contains", "")), x.get("decision"), cell(x.get("why", ""))) for x in acks]
        out += [""]
    out += [
           "## Lifecycle counts", "", "| Lifecycle | Records |", "|---|---|"]
    out += ["| %s | %d |" % (l, c.get(l, 0)) for l in LIFECYCLES]
    out += ["", "## Superseded records and what governs instead", "",
            "| Record | Title | Superseded by | Governing record now | Governing lifecycle | Why superseded |", "|---|---|---|---|---|---|"]
    for r in reqs:
        if lifecycle(r) != "SUPERSEDED":
            continue
        g, chain, problem = governing(r, by_id)
        gid = g["id"] if g else "(%s)" % problem
        out.append("| %s | %s | %s | %s | %s | %s |" % (r["id"], cell(r.get("title", ""))[:90], r.get("superseded_by") or "(none)",
                                                       gid, lifecycle(g) if g else "", cell(last_why(r))[:140]))
    out += ["", "## Active owner decisions and rules (in force; implementation status does not retire them)", "",
            "| Record | Kind | Title | Supersedes |", "|---|---|---|---|"]
    for r in reqs:
        if r.get("kind") in ("decision", "rule") and lifecycle(r) == "ACTIVE":
            out.append("| %s | %s | %s | %s |" % (r["id"], r["kind"], cell(r.get("title", ""))[:110], ", ".join(as_list(r.get("supersedes")))))
    out += ["", "## Under review (not authority until the owner decides)", "",
            "| Record | Kind | Title |", "|---|---|---|"]
    for r in reqs:
        if lifecycle(r) == "UNDER REVIEW":
            out.append("| %s | %s | %s |" % (r["id"], r.get("kind"), cell(r.get("title", ""))[:120]))
    out += ["", "Active and completed requirements are listed with their status in `STATUS.md` and the build views; "
            "COMPLETED means the implementation met its acceptance criteria, not that a decision stopped governing.", ""]
    return "\n".join(out)


if __name__ == "__main__":
    import json
    import sys
    d = json.loads((REPO / "docs/requirements/requirements.json").read_text())
    probs = record_errors(d) + document_errors(d)
    print(Counter(lifecycle(r) for r in d["requirements"]))
    for p in probs:
        print("problem:", p)
    sys.exit(1 if probs else 0)
