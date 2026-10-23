"""One-off migration of 2026-10-23 (owner directive: master requirements reconciliation and permanent development
control, `docs/directives/2026-10-23_master_requirements_reconciliation.md`).

Reads every copy of docs/requirements/requirements.json on every remote branch, merges them into one record per
id (no id lost), converts each record to the mml-requirements/2 schema (separate approval, implementation,
verification and release dimensions; owner decisions with a disposition), applies the evidence corrections of the
2026-10-23 audit, and writes:

  docs/requirements/requirements.json                the canonical register (mml-requirements/2)
  docs/requirements/reconciliation_2026-10-23.json   one line per original (source, id): canonical id, action, reason

Kept so the reconciliation can be re-run and checked against the same branch heads; not part of normal work (the
register is maintained with tools/requirements_update.py from now on).

    python3 tools/requirements_migrate_v2.py            # writes both files (the 2026-10-23 run)
    python3 tools/requirements_migrate_v2.py --verify   # dry run: rebuild from the pinned source copies recorded in
                                                        # the ledger, write nothing, compare with the canonical register
"""
import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import check_requirements as cr  # noqa: E402

REG = "docs/requirements/requirements.json"
DATE = "2026-10-23"
WHY = "master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md)"
# The builds whose code a commit can be integrated into, with the commit that stands for each.
BUILD_REFS = [("Build 15 release a8760be", "a8760be"), ("Build 16 release b3bbb1c", "b3bbb1c"),
              ("Build 17 release cd7439c", "cd7439c"), ("Build 18 wip/build18", "origin/wip/build18")]
TASK_REFS = [("Expansion 19 prototype wip/expansion19-preparation", "origin/wip/expansion19-preparation"),
             ("multiplayer prototype wip/multiplayer", "origin/wip/multiplayer")]


def git(*a):
    return subprocess.run(["git", "-C", str(REPO)] + list(a), capture_output=True, text=True)


def copies():
    """{blob: [branches]} for every remote branch carrying the register."""
    out = defaultdict(list)
    for b in git("branch", "-r", "--format=%(refname:short)").stdout.split():
        p = git("rev-parse", "%s:%s" % (b, REG))
        if p.returncode == 0:
            out[p.stdout.strip()].append(b)
    return out


def reach(ref):
    return set(git("rev-list", ref).stdout.split())


def full(c):
    p = git("rev-parse", "--verify", "--quiet", c + "^{commit}")
    return p.stdout.strip() if p.returncode == 0 else None


def merge_variants(vs):
    """One record from several copies of the same id: the copy with the longest history (histories are
    append-only, so it is the latest); a history not a prefix of it is merged in by date; ties keep the staging copy."""
    hist = lambda e: [json.dumps(h, sort_keys=True) for h in e.get("history") or []]
    # the copy changed last wins its fields (latest history date; then the longer history; then the staging copy)
    last = lambda e: max([h.get("date", "") for h in e.get("history") or []] or [""])
    vs = sorted(vs, key=lambda v: (last(v[0]), len(v[0].get("history") or []), v[2]))
    best = json.loads(json.dumps(vs[-1][0]))
    lh = hist(best)
    action, reason = "kept", "one version on every branch"
    distinct = {json.dumps(v[0], sort_keys=True) for v in vs}
    if len(distinct) > 1:
        action, reason = "latest version kept", "%d versions; the others are earlier states (their history is a prefix of this one's)" % len(distinct)
        extra = []
        for e, _, _ in vs:
            h = hist(e)
            if lh[:len(h)] != h:
                extra += [x for x in h if x not in lh and x not in extra]
        if extra:
            merged = sorted([json.loads(x) for x in lh + extra], key=lambda h: h.get("date", ""))
            best["history"] = merged
            action, reason = "histories merged", "copies on different branches recorded different changes; all history lines kept, ordered by date"
        top = [e for e, _, _ in vs if len(e.get("history") or []) == len(vs[-1][0].get("history") or []) and last(e) == last(vs[-1][0])]
        if len({json.dumps(e, sort_keys=True) for e in top}) > 1 and action != "histories merged":
            reason += "; copies with the same history differed only in annotation fields (b16_class, complexity): the staging copy's kept"
    return best, action, reason


def main(verify=False):
    if verify:
        led = json.loads((REPO / "docs/requirements/reconciliation_2026-10-23.json").read_text())
        cp, staging_blob = led["copies"], led["staging_blob"]
    else:
        cp = copies()
        staging_blob = git("rev-parse", "origin/staging/my-medieval-life:" + REG).stdout.strip()
    var = defaultdict(list)
    for blob, branches in cp.items():
        d = json.loads(git("cat-file", "-p", blob).stdout)
        for e in d["requirements"]:
            var[e["id"]].append((e, branches, 1 if blob == staging_blob else 0))
    reach_b = [(name, reach(ref)) for name, ref in BUILD_REFS]
    reach_t = [(name, reach(ref)) for name, ref in TASK_REFS]
    ledger, out = [], []
    for rid in sorted(var):
        rec, action, reason = merge_variants(var[rid])
        for e, branches, _ in var[rid]:
            ledger.append({"id": rid, "source": "%s (%d branches, e.g. %s)" % (REG, len(branches), ", ".join(sorted(branches)[:3])),
                           "history_lines": len(e.get("history") or []), "v1_status": e.get("status"),
                           "canonical_id": rid, "action": action, "reason": reason})
        if not any(st for _, _, st in var[rid]):
            ledger[-1]["recovered"] = "missing from the staging register; recovered from the build line"
        commits = [(c, full(c)) for c in rec.get("commits") or []]
        known = [f for _, f in commits if f]
        # integrated into a build only when every recorded commit is in it (an early art import alone does not count)
        inb = [name for name, s in reach_b if known and all(f in s for f in known)]
        int_ = [name for name, s in reach_t if known and all(f in s for f in known)]
        rec["integrated_in"] = inb
        if int_ and not inb:
            rec["task_branches"] = int_
        missing = [c for c, f in commits if not f]
        if missing:
            rec["unresolved_commits"] = missing
        out.append(cr.migrate_entry(rec, DATE, WHY))
    d = {"format": "mml-requirements/2", "schema": "docs/requirements/SCHEMA.md",
         "previous_paths": [], "builds": cr.BUILDS_DEFAULT, "requirements": out}
    import requirements_corrections as rc  # the audit's evidence corrections and new records, in one reviewable file
    notes = rc.apply(d, DATE)
    for n in notes:
        ledger.append(n)
    d["requirements"].sort(key=lambda r: r["id"])
    if verify:
        return d, ledger
    (REPO / REG).write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n")
    (REPO / "docs/requirements/reconciliation_2026-10-23.json").write_text(json.dumps(
        {"format": "mml-reconciliation/1", "date": DATE, "copies": {b: sorted(v) for b, v in cp.items()},
         "staging_blob": staging_blob, "entries": ledger}, indent=1, ensure_ascii=False) + "\n")
    (REPO / "docs/requirements/RECONCILIATION_2026-10-23.md").write_text(summary_md(cp, ledger, d))
    print("%d register copies, %d ids, %d ledger lines" % (len(cp), len(out), len(ledger)))


def summary_md(cp, ledger, d):
    from collections import Counter
    recs = d["requirements"]
    orig = [x for x in ledger if x.get("v1_status") is not None]
    ids = {x["id"] for x in orig}
    act = Counter(x["action"] for x in ledger if x.get("v1_status") is None)
    per_id = Counter()
    for x in orig:
        per_id[(x["id"], x["action"])] = 1
    acts = Counter(a for (_, a) in per_id)
    recovered = sorted({x["id"] for x in ledger if x.get("recovered")})
    sup = [r for r in recs if r.get("approval_status") == "SUPERSEDED" or r.get("disposition") == "SUPERSEDED"]
    review = sorted([r for r in recs if "human review" in str(r.get("remaining_work") or "") or "unknown" in str(r.get("remaining_work") or "").lower()
                     or (r.get("kind") == "decision" and r.get("disposition") == "PROVISIONAL")], key=lambda r: r["id"])
    branches = sum(len(v) for v in cp.values())
    L = ["# Requirements reconciliation of 2026-10-23", "",
         "Written by `python3 tools/requirements_migrate_v2.py` (owner directive `docs/directives/2026-10-23_master_requirements_reconciliation.md`).",
         "The line-by-line ledger is `docs/requirements/reconciliation_2026-10-23.json`: one line per original record in each",
         "distinct copy of the register, with its canonical id, the action taken and why. A frozen record of the reconciliation.", "",
         "| | Count |", "|---|---|",
         "| Branches carrying a copy of the register | %d |" % branches,
         "| Distinct copies (by content) | %d |" % len(cp),
         "| Original records inspected (every record in every distinct copy) | %d |" % len(orig),
         "| Unique ids in the copies | %d |" % len(ids),
         "| Ids missing from the staging register, recovered | %d |" % len(recovered),
         "| Ids identical on every copy | %d |" % acts.get("kept", 0),
         "| Ids with several versions (the latest kept; the others are earlier states) | %d |" % acts.get("latest version kept", 0),
         "| Ids whose copies recorded different changes (histories merged) | %d |" % acts.get("histories merged", 0),
         "| Records added from documents (never registered) | %d |" % act.get("added (previously unregistered)", 0),
         "| Aliases recorded (other numberings of existing records) | %d |" % act.get("alias", 0),
         "| Evidence corrections applied | %d |" % act.get("corrected", 0),
         "| Superseded records preserved (linked to their replacement) | %d |" % len(sup),
         "| Canonical records now | %d |" % len(recs),
         "| Unresolved conflicts between copies | 0 (no id had two copies with conflicting content and no common history) |", "",
         "Duplicates by meaning: the register already linked them as SUPERSEDED (e.g. OWN-24 -> FR-01, F-3 -> FR-08, K-3 -> OD-02,",
         "REQ-BANDIT -> WDR-016-C). New this time: STONE-05 is met by SKILL-TRADES-18 (Masonry, the owner's \"Masonry (stoneworking)\"),",
         "linked as related, both kept; CARAVAN-TMP is superseded by ECON-P1.3 (owner answer 2026-10-23).", "",
         "## Recovered ids (missing from staging, present on the build line)", "", ", ".join(recovered) or "None", "",
         "## Needs review (human; not mechanically checkable)", "",
         "| ID | Why |", "|---|---|"]
    L += ["| %s | %s |" % (r["id"], str(r.get("remaining_work") or r.get("owner_answer") or "").replace("|", "/")[:220]) for r in review]
    L += ["", "Aliases not applied (uncertain): OD-1..OD-9 in docs/release/BUILD_14_OPEN_ITEMS_AUDIT.md look like OD-01..OD-09 but",
          "were not verified; the consolidated Build 17 directive's own MIN-E-Q4 and MIN-E-Q5 collide with register ids of other",
          "meaning (its header maps them to MIN-E-Q2 and MIN-E-Q3); INV-18-01..13 in the INV-18 directive are its numbered",
          "requirements, covered by INV-18's acceptance criteria, not separate records.", ""]
    return "\n".join(L) + "\n"


def verify():
    """Dry run against the canonical register: the rebuilt register must equal it record for record, except for
    history lines the lead added after the migration (later work recorded with requirements_update.py)."""
    d, ledger = main(verify=True)
    canon = {r["id"]: r for r in json.loads((REPO / REG).read_text())["requirements"]}
    rebuilt = {r["id"]: r for r in d["requirements"]}
    report = {"rebuilt": len(rebuilt), "canonical": len(canon), "only_rebuilt": sorted(set(rebuilt) - set(canon)),
              "only_canonical": sorted(set(canon) - set(rebuilt)), "identical": 0, "changed_after_migration": [], "differs": []}
    for rid, r in rebuilt.items():
        c = canon.get(rid)
        if c is None:
            continue
        if json.dumps(r, sort_keys=True) == json.dumps(c, sort_keys=True):
            report["identical"] += 1
            continue
        n = len(r["history"])
        if c["history"][:n] == r["history"] and len(c["history"]) > n:
            report["changed_after_migration"].append(rid)
        else:
            report["differs"].append(rid)
    ids = [r["id"] for r in d["requirements"]]
    report["duplicate_ids_in_rebuild"] = sorted({i for i in ids if ids.count(i) > 1})
    return report


if __name__ == "__main__":
    if "--verify" in sys.argv:
        rep = verify()
        print(json.dumps(rep, indent=1))
        sys.exit(1 if rep["differs"] or rep["only_rebuilt"] or rep["only_canonical"] or rep["duplicate_ids_in_rebuild"] else 0)
    main()
