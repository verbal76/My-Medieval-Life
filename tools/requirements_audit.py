"""Requirements recovery audit of 2026-10-23 (owner directive docs/directives/2026-10-23_requirements_recovery_audit.md,
REQ-CTRL-02): migration verification, provenance and evidence gaps, code without tracking, the classification of
recovered and corrected records by build, and the owner-decision audit.

Reads the canonical register, the reconciliation ledger (its pinned source copies) and git; writes
docs/requirements/AUDIT_2026-10-23.md and docs/requirements/audit_2026-10-23.json. Read-only otherwise.

    python3 tools/requirements_audit.py
"""
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import check_requirements as cr  # noqa: E402
import requirements_migrate_v2 as mig  # noqa: E402
import requirements_report as rr  # noqa: E402

LEDGER = REPO / "docs/requirements/reconciliation_2026-10-23.json"
OUT_MD = REPO / "docs/requirements/AUDIT_2026-10-23.md"
OUT_JSON = REPO / "docs/requirements/audit_2026-10-23.json"
CODE_REFS = ["origin/wip/build18", "origin/wip/build17", "origin/wip/expansion18-preparation", "origin/wip/expansion19-preparation",
             "origin/wip/multiplayer", "origin/staging/my-medieval-life"]
BUILDS = ["18", "19", "20", "21", "22", "23", "24", "25"]

# The agent's assessment of each open decision (not a decision): is it owner-level, can work continue without it.
ASSESS = {
    "STONE-D1": ("owner-level as written (the documents list it as an owner question); the values could be provisional engineering defaults if the owner allows", "no for the stonecutter chain; yes for everything else"),
    "STONE-D2": ("owner-level as written; a provisional recipe and wear rate would be an engineering default if the owner allows", "no for the iron chisel and stonecutter; yes otherwise"),
    "X18-FEES": ("engineering choice with a provisional default (couriers.json); the owner may review the numbers", "yes"),
    "Q18-11": ("owner-level: final pay and output percentages; waits for X18-SIM evidence; the approved candidate runs meanwhile", "yes"),
    "Q18-6": ("needs only the owner's confirmation of the agent's reading (settled by Q18-3)", "yes"),
    "X19-DECAY": ("owner-level: tied to the calendar question the owner raised", "yes until Build 19's calibration gate (SJD-G)"),
    "CON-08-Q": ("engineering choice with a working default (50 coins)", "yes"),
    "OD-02": ("owner review of every provisional number; a standing review, not a blocker", "yes"),
    "OD-03": ("owner-level design questions (isometric, magic, era, county); none in Builds 18-21 scope", "yes"),
    "OD-04": ("owner-level (chests and locks); not in Builds 18-21 scope", "yes"),
    "OD-07": ("small owner-level gameplay question (hunting in Gather mode)", "yes"),
    "OD-09": ("owner-level open design items of GAME_DESIGN.md", "yes"),
    "OD-17": ("owner-level (Game Designer spec calls); Build 16 record left open", "yes"),
}


def git(*a):
    return subprocess.run(["git", "-C", str(REPO)] + list(a), capture_output=True, text=True).stdout


def main():
    d = cr.load((REPO / cr.REGISTER).read_text())
    R = {r["id"]: r for r in d["requirements"]}
    led = json.loads(LEDGER.read_text())
    staging_v1 = {e["id"]: e for e in json.loads(git("cat-file", "-p", led["staging_blob"]))["requirements"]}
    # ---- 1. sources and the dry run -------------------------------------------------------------------------------
    variants = defaultdict(dict)
    total = 0
    for blob, branches in led["copies"].items():
        for e in json.loads(git("cat-file", "-p", blob))["requirements"]:
            total += len(branches)
            variants[e["id"]].setdefault(json.dumps(e, sort_keys=True), []).extend(branches)
    distinct_records = sum(len(v) for v in variants.values())
    ver = mig.verify()
    # ---- 2. conflicts between copies (owner fields that differ where neither history contains the other) --------
    def hist(e):
        return [json.dumps(h, sort_keys=True) for h in e.get("history") or []]
    conflicts, evolutions = [], []
    for rid, vs in variants.items():
        es = [json.loads(k) for k in vs]
        for f in ("kind", "owner_answer", "owner_wording", "canceled_by_owner", "superseded_by"):
            vals = {json.dumps(e.get(f)) for e in es if e.get(f) not in (None, "", [])}
            if len(vals) <= 1:
                continue
            ordered = sorted(es, key=lambda e: len(e.get("history") or []))
            prefix = all(hist(ordered[-1])[:len(hist(e))] == hist(e) for e in ordered)
            (evolutions if prefix else conflicts).append({"id": rid, "field": f, "values": len(vals)})
    # the merge rule never preferred a copy with less history (the newest commit is not assumed to hold the newest decision)
    shorter_kept = [rid for rid, vs in variants.items()
                    if max(len(json.loads(k).get("history") or []) for k in vs) > len([h for h in R[rid]["history"] if not h["change"].startswith(("schema v2", "reconciliation"))]) + 0
                    and not any(json.loads(k).get("history") == [h for h in R[rid]["history"] if h in json.loads(k).get("history", [])] for k in vs)]
    # superseded or rejected in any copy but open now (reactivation check)
    reactivated = sorted({rid for rid, vs in variants.items() for k in vs
                          if json.loads(k).get("status") in ("SUPERSEDED", "CANCELED BY OWNER") and cr.is_open(R[rid])})
    # proposals or ideas in every copy, approved now
    promoted = sorted(rid for rid, vs in variants.items()
                      if all(json.loads(k)["kind"] in ("proposal", "idea") for k in vs) and R[rid]["kind"] == "approved")
    # build moves relative to the staging register before the reconciliation
    moved = sorted((rid, staging_v1[rid].get("target_build"), R[rid].get("target_build")) for rid in R
                   if rid in staging_v1 and staging_v1[rid].get("target_build") != R[rid].get("target_build"))
    # ---- 3. provenance and evidence gaps ----------------------------------------------------------------------------
    gaps = defaultdict(lambda: defaultdict(list))
    for r in d["requirements"]:
        if r["kind"] != "approved" or r.get("umbrella"):
            continue
        b = r.get("target_build") or "none"
        im = r.get("implementation_status")
        if im in ("INTEGRATED", "PARTIALLY IMPLEMENTED", "IMPLEMENTED ON TASK BRANCH"):
            if not r.get("commits"):
                gaps[b]["no commit recorded"].append(r["id"])
            if r.get("legacy_evidence") and not r.get("integrated_in"):
                gaps[b]["integration shown only by legacy (v1) evidence"].append(r["id"])
            if r.get("verification_status") == "NOT TESTED":
                gaps[b]["no test evidence"].append(r["id"])
        for c in r.get("unresolved_commits") or []:
            gaps[b]["commit id that does not resolve"].append("%s (%s)" % (r["id"], c))
    # ---- 4. code that exists for records tracked as not started -------------------------------------------------------
    msgs = {}
    for ref in CODE_REFS:
        for line in git("log", "--format=%h %s", ref).splitlines():
            h, _, subj = line.partition(" ")
            msgs.setdefault(h, (ref, subj))
    untracked_code = []
    for r in d["requirements"]:
        if r["kind"] != "approved" or r.get("implementation_status") not in ("NOT STARTED", "READY", "IMPLEMENTATION BLOCKED"):
            continue
        pat = re.compile(r"(?<![A-Z0-9-])%s(?![A-Z0-9])" % re.escape(r["id"]))
        hits = [(h, ref, subj) for h, (ref, subj) in msgs.items() if pat.search(subj)]
        if hits:
            untracked_code.append({"id": r["id"], "build": r.get("target_build"), "commits": [h for h, _, _ in hits[:5]],
                                   "subjects": [s[:90] for _, _, s in hits[:2]]})
    # ---- 5. recovered and corrected records, classified by build ------------------------------------------------------
    recovered = sorted({x["id"] for x in led["entries"] if x.get("recovered")})
    added = sorted({x["id"] for x in led["entries"] if x.get("action") == "added (previously unregistered)"})
    corrected = sorted({x["id"] for x in led["entries"] if x.get("action") == "corrected"} - set(added))
    aliases = sorted({(x["id"], x["canonical_id"]) for x in led["entries"] if x.get("action") == "alias"})

    def klass(r):
        if r["kind"] == "decision":
            return "superseded or canceled" if r.get("disposition") == "SUPERSEDED" else (
                "awaiting an owner decision" if r.get("disposition") in ("OPEN", "PROVISIONAL", "REOPENED") else "owner decision already answered")
        if r["kind"] in ("proposal", "idea"):
            return "unapproved proposal"
        if r.get("approval_status") in ("SUPERSEDED", "REJECTED"):
            return "superseded or canceled"
        if r.get("umbrella"):
            return "umbrella (children counted)"
        im = r.get("implementation_status")
        if r.get("completion") == "COMPLETE":
            return "already completed"
        if im == "INTEGRATED":
            return "implemented (integrated), verification outstanding"
        if im in ("PARTIALLY IMPLEMENTED", "IMPLEMENTED ON TASK BRANCH"):
            return "partially implemented"
        if r.get("design") == "OWNER DECISION REQUIRED" or r.get("approval_status") == "OWNER DECISION REQUIRED":
            return "awaiting an owner decision"
        return "approved and still outstanding"
    table = defaultdict(Counter)
    detail = defaultdict(list)
    for group, ids in (("recovered (absent from staging)", recovered), ("added from documents", added), ("status corrected", corrected)):
        for rid in ids:
            r = R[rid]
            b = r.get("target_build") or "none"
            k = klass(r)
            table[(group, b)][k] += 1
            detail[group].append((rid, b, k))
    for a, c in aliases:
        table[("alias (duplicate numbering)", R[c].get("target_build") or "none")]["duplicate of an existing requirement"] += 1
    # ---- 6. decisions ----------------------------------------------------------------------------------------------------
    open_dec = [r for r in d["requirements"] if r["kind"] == "decision" and r.get("disposition") in ("OPEN", "PROVISIONAL", "REOPENED")]
    proposals_open = [r for r in d["requirements"] if r["kind"] == "proposal" and cr.is_open(r)]
    # ---- write ------------------------------------------------------------------------------------------------------------
    out = {"sources": {"branch_copies": sum(len(v) for v in led["copies"].values()), "distinct_copies": len(led["copies"]),
                       "records_in_branch_copies": total, "records_in_distinct_copies": sum(1 for x in led["entries"] if x.get("v1_status") is not None),
                       "distinct_record_versions": distinct_records, "unique_ids": len(variants),
                       "ids_identical_everywhere": sum(1 for v in variants.values() if len(v) == 1)},
           "dry_run": ver, "conflicts": conflicts, "evolutions": evolutions, "reactivated": reactivated, "promoted": promoted,
           "moved": moved, "gaps": {b: dict(v) for b, v in gaps.items()}, "untracked_code": untracked_code,
           "recovered": recovered, "added": added, "corrected": corrected, "aliases": aliases,
           "classification": {"%s|%s" % k: dict(v) for k, v in table.items()},
           "open_decisions": [x["id"] for x in open_dec], "open_proposals": [x["id"] for x in proposals_open]}
    OUT_JSON.write_text(json.dumps(out, indent=1, ensure_ascii=False) + "\n")
    OUT_MD.write_text(render(d, R, out, detail, open_dec, proposals_open, staging_v1))
    print("audit written: %s" % OUT_MD.relative_to(REPO))


def render(d, R, o, detail, open_dec, props, staging_v1):
    s, v = o["sources"], o["dry_run"]
    c = lambda x: cr._cell(x)
    L = ["# Requirements recovery audit, 2026-10-23", "",
         "Written by `python3 tools/requirements_audit.py` (owner directive `docs/directives/2026-10-23_requirements_recovery_audit.md`,",
         "REQ-CTRL-02) from the canonical register, the reconciliation ledger and git. Status by build: `docs/requirements/views/`.", "",
         "## 1. Sources and the dry run", "",
         "| | Count |", "|---|---|",
         "| Branch copies of the register at the reconciliation | %d |" % s["branch_copies"],
         "| Distinct copies (by content; archived on `wip/requirements-sources-2026-10-23`) | %d |" % s["distinct_copies"],
         "| Source records across all branch copies | %d |" % s["records_in_branch_copies"],
         "| Source records across the distinct copies | %d |" % s["records_in_distinct_copies"],
         "| Distinct record versions | %d |" % s["distinct_record_versions"],
         "| Unique requirement ids | %d |" % s["unique_ids"],
         "| Ids identical in every copy | %d |" % s["ids_identical_everywhere"],
         "| Exact duplicate records (same id and content on several branches) | %d |" % (s["records_in_branch_copies"] - s["distinct_record_versions"]),
         "| Dry run: records rebuilt from the pinned sources | %d (canonical %d) |" % (v["rebuilt"], v["canonical"]),
         "| Dry run: identical to the canonical register | %d |" % v["identical"],
         "| Dry run: changed after the migration by recorded later work (history lines added) | %d |" % len(v["changed_after_migration"]),
         "| Dry run: unexplained differences | %d |" % len(v["differs"]),
         "| Dry run: duplicate ids produced by a re-run | %d |" % len(v["duplicate_ids_in_rebuild"]),
         "| Conflicting owner fields between copies (neither history contains the other) | %d |" % len(o["conflicts"]),
         "| Owner fields that changed over time (later copy records the change) | %d |" % len(o["evolutions"]),
         "| Superseded or canceled in any copy but open now (reactivated) | %d |" % len(o["reactivated"]),
         "| Proposals or ideas in every copy, approved now | %d (%s) |" % (len(o["promoted"]), ", ".join(o["promoted"]) or "none"),
         "| Records with a different build than in the pre-reconciliation staging register | %d |" % len(o["moved"]),
         "| Missing from the staging register, recovered | %d |" % len(o["recovered"]),
         "| Found in documents, never registered, added | %d |" % len(o["added"]),
         "| Status corrected from evidence | %d |" % len(o["corrected"]),
         "| Duplicate numberings recorded as aliases | %d |" % len(o["aliases"]),
         "| Open owner decisions / open proposals awaiting the owner | %d / %d |" % (len(open_dec), len(props)), ""]
    if o["conflicts"]:
        L += ["Conflicts (preserved for owner review):", ""] + ["- %s: %s (%d values)" % (x["id"], x["field"], x["values"]) for x in o["conflicts"]] + [""]
    L += ["Owner fields that evolved (each later copy carries the change in its history): " +
          ", ".join(sorted({"%s (%s)" % (x["id"], x["field"]) for x in o["evolutions"]})) + ".", "",
          "Build assignments that differ from the pre-reconciliation staging register (each with a history line and its evidence; "
          "listed for the owner to confirm):", "", "| ID | Before | Now | Evidence |", "|---|---|---|---|"]
    for rid, a, b in o["moved"]:
        why = next((h["why"] for h in reversed(R[rid]["history"]) if "target_build" in h.get("change", "")), "")
        L.append("| %s | %s | %s | %s |" % (rid, a, b, c(why)[:160]))
    L += ["", "## 2. Provenance and evidence gaps (approved, non-umbrella records)", ""]
    for b in BUILDS + sorted(k for k in o["gaps"] if k not in BUILDS):
        g = o["gaps"].get(b)
        if not g:
            continue
        L.append("- **%s:** " % (("Build " + b) if b in BUILDS else ("target " + b)) + "; ".join("%s %d (%s)" % (k, len(x), ", ".join(x[:12]) + (" …" if len(x) > 12 else "")) for k, x in g.items()))
    L += ["", "Code that exists for records tracked as not started (commit subjects naming the id on the integration and "
          "prospective branches; each needs a human look: a mention is not proof of implementation):", ""]
    L += ["- %s (Build %s): %s — %s" % (x["id"], x["build"], ", ".join(x["commits"]), c("; ".join(x["subjects"]))) for x in o["untracked_code"]] or ["- none found"]
    L += ["", "## 3. Records absent from or misrepresented in the previous authoritative register, by build", "",
          "| Group | Build | Classification | Count |", "|---|---|---|---|"]
    for key, cnt in sorted(o["classification"].items()):
        g, b = key.split("|")
        for k, n in sorted(cnt.items()):
            L.append("| %s | %s | %s | %d |" % (g, b, k, n))
    for g in ("recovered (absent from staging)", "added from documents", "status corrected"):
        rows = [x for x in detail[g] if x[1] in BUILDS]
        if rows:
            L += ["", "%s, Builds 18-21: " % g.capitalize() + "; ".join("%s (B%s, %s)" % x for x in rows)]
    L += ["", "## 4. Open owner decisions and proposals awaiting the owner", "",
          "| ID | Build | Question | Disposition | Current direction | Blocks | Assessment (agent) | Work continues? |", "|---|---|---|---|---|---|---|---|"]
    for x in sorted(open_dec, key=lambda r: (str(r.get("target_build")), r["id"])):
        a, cont = ASSESS.get(x["id"], ("owner-level (Build %s design)" % x.get("target_build") if x.get("target_build") in ("20", "21") else "owner-level", "no for its build" if x.get("blocks_implementation") else "yes"))
        L.append("| %s | %s | %s | %s | %s | %s | %s | %s |" % (x["id"], x.get("target_build"), c(x["title"])[:120], x["disposition"],
                 c(x.get("owner_answer") or "none")[:120], ", ".join(rr.affected(d, x["id"])) or "-", c(a), c(cont)))
    L += ["", "Proposals awaiting the owner (not approved work; not counted): " + ", ".join(sorted(x["id"] for x in props)) + ".", ""]
    return "\n".join(L) + "\n"


if __name__ == "__main__":
    main()
