"""Validate the requirements register and detect silently lost requirements or decisions (owner directives
2026-10-19, docs/directives/2026-10-19_build14_readiness_requirements_preservation.md, and 2026-10-23,
docs/directives/2026-10-23_master_requirements_reconciliation.md).

The register is docs/requirements/requirements.json (mml-requirements/2; schema in docs/requirements/SCHEMA.md): the
one manually maintained list of every requirement, proposal, idea, design rule and owner decision. Everything else is
generated from it by --write: docs/DEVELOPMENT_LEDGER.md, the views in docs/requirements/views/ and the
reconciliation reports of the frozen baselines.

Checks (any failure exits 1; an unfinished requirement is never a failure):
  - identity: unique ids of the allowed shape; aliases unique and never another record's id;
  - fields: title, source, history; acceptance criteria for approved work; approval evidence for approved work;
  - statuses: each dimension (approval, implementation, verification, release, completion; a decision's
    disposition) holds a known value, and the dimensions do not contradict each other (e.g. COMPLETE needs integrated,
    verified code; RELEASED needs COMPLETE; nothing unapproved is a release candidate);
  - evidence: INTEGRATED names commits, an integration or legacy evidence; a verification level names its tests or
    playtest record; IN DEVELOPMENT names a worker and a branch and is listed in docs/CURRENT_DEVELOPMENT_STATE.md;
  - references: parent, depends_on, related, decisions, superseded_by and supersedes name existing records; parent
    chains do not loop; an owner decision is answered (APPROVED, PROVISIONAL) only with the owner's words;
  - builds: target_build is a known build or backlog; work on a build that is not authorized has not started;
  - documents named in any field exist; the roadmap anchors exist; the project memory files exist and name real paths;
  - frozen baselines (docs/requirements/baseline_*.json) and --against REF: no id disappears, no status changes
    without a new history line (older registers are read through the same v1 -> v2 mapping);
  - every generated file is up to date (run --write).

    python3 tools/check_requirements.py                 # validate
    python3 tools/check_requirements.py --write         # validate and regenerate the ledger and the views
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
FORMAT = "mml-requirements/2"

KINDS = {"approved": "Approved requirement", "proposal": "Proposal awaiting an owner decision (not approved)",
         "decision": "Owner decision", "rule": "World design rule", "idea": "Unapproved idea",
         "rejected": "Rejected proposal"}
APPROVAL = ["PROPOSED", "OWNER APPROVED", "OWNER DECISION REQUIRED", "DEFERRED", "REJECTED", "SUPERSEDED"]
IMPLEMENTATION = ["NOT STARTED", "READY", "IN DEVELOPMENT", "PARTIALLY IMPLEMENTED", "IMPLEMENTED ON TASK BRANCH",
                  "INTEGRATED", "IMPLEMENTATION BLOCKED", "NOT APPLICABLE"]
VERIFICATION = ["NOT TESTED", "TARGETED TESTS PASSED", "INTEGRATION VERIFIED", "GAMEPLAY VERIFIED", "OWNER PLAYTESTED",
                "VERIFICATION FAILED", "NOT APPLICABLE"]
RELEASE = ["NOT READY", "RELEASE BLOCKED", "RELEASE CANDIDATE", "RELEASE READY", "RELEASED", "UNKNOWN", "NOT APPLICABLE"]
COMPLETION = ["OPEN", "COMPLETE", "CLOSED"]
DISPOSITION = ["OPEN", "APPROVED", "PROVISIONAL", "SUPERSEDED", "REOPENED", "DEFERRED"]
DESIGN = ["SPECIFIED", "PARTIAL", "OWNER DECISION REQUIRED", "DESIGN WORK REQUIRED", "UNKNOWN"]
EFFORT = ["XS", "S", "M", "L", "XL", "UNKNOWN"]
VERIFIED_LEVEL = {v: i for i, v in enumerate(VERIFICATION[:5])}
## Where an entry belongs. "20+" is the unassigned future backlog (owner, ROAD-01: Build 20 or later).
TARGETS = ["15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "20+", "unassigned", "multiplayer", "owner decision", "owner action"]
TARGET_NAMES = {"15": "Build 15: simulation stabilization", "16": "Build 16: long-term equilibrium and validation",
                "17": "Build 17: Mining & Industrial Development", "18": "Build 18: combined release (tracks A, B, C)",
                "19": "Build 19: NPC Judgment System", "20": "Build 20: Living Economy",
                "21": "Build 21: Village Politics", "22": "Build 22: Settlement Advancement Phase 2",
                "23": "Build 23: Bandit Factions and Criminal Careers", "24": "Build 24: Generational Legacy", "25": "Build 25: Weather and Natural Disasters", "20+": "Future backlog (Build 20 or later, not assigned)",
                "unassigned": "Approved, no build assigned", "multiplayer": "Multiplayer track (isolated branch)",
                "owner decision": "Waiting on an owner decision for its build", "owner action": "Owner or external action (not development work)"}
## Build authorization and status; changed only with the owner's word (a history line in the build's anchor entry).
BUILDS_DEFAULT = {
    "15": {"name": "Simulation stabilization", "implementation_authorized": True, "released": "private draft a8760be"},
    "16": {"name": "Long-term equilibrium", "implementation_authorized": True, "released": "public b3bbb1c"},
    "17": {"name": "Mining & Industrial Development", "implementation_authorized": True, "released": "private playtest draft 80e6b99 (code cd7439c)"},
    "18": {"name": "Combined release (tracks A, B, C)", "implementation_authorized": True, "integration_branch": "wip/build18",
           "released": "", "authority": "B18-DIR, B18-SCOPE; no distributable without the owner's approval"},
    "19": {"name": "NPC Judgment", "implementation_authorized": True, "integration_branch": "",
           "released": "", "authority": "PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete"},
    "20": {"name": "Living Economy", "implementation_authorized": False, "released": "",
           "authority": "OD-30, OD-LE-01: numbering and placement only; implementation not authorized"},
    "21": {"name": "Village Politics", "implementation_authorized": False, "released": "",
           "authority": "OD-30: numbering only; implementation not authorized"},
    "22": {"name": "Settlement Advancement Phase 2", "implementation_authorized": False, "released": "",
           "authority": "OD-30 (renumbered 2026-10-23): numbering only"},
    "23": {"name": "Bandit Factions and Criminal Careers", "implementation_authorized": False, "released": "",
           "authority": "OD-30 (renumbered 2026-10-23): numbering only"},
    "24": {"name": "Generational Legacy", "implementation_authorized": False, "released": "",
           "authority": "OD-30 (renumbered 2026-10-23): numbering only"},
    "25": {"name": "Weather and Natural Disasters", "implementation_authorized": False, "released": "",
           "authority": "WEATHER-01 (owner 2026-10-23): design only, no code"},
}
ID_RE = re.compile(r"^[A-Z][A-Z0-9]*(-[A-Z0-9.]+)+$")
DOC_RE = re.compile(r"\b((?:docs|tools|game|tests)/[\w./-]+\.(?:md|json|py|gd|cfg|pdf|txt))")
MEMORY = REPO / "docs" / "PROJECT_MEMORY.md"
STATE = REPO / "docs" / "CURRENT_DEVELOPMENT_STATE.md"
ANCHORS = ["ROAD-01", "EQ-16", "EXP-A", "EXP-B", "EXP-C"] + ["SJD-Q%02d" % i for i in range(1, 15)]
LINK_RE = re.compile(r"`((?:docs|tools|game|tests|\.github|\.claude)/[^`*\s]+|CLAUDE\.md)`")
REF_LISTS = ("depends_on", "related", "decisions")
## Paths named by a record may live on an integration or prospective branch rather than on staging (code and design
## notes of Builds 17-21); a path counts as existing if it is in the working tree or on one of these branches.
PATH_REFS = ["origin/staging/my-medieval-life", "origin/wip/build18", "origin/wip/build17", "origin/wip/expansion18-preparation", "origin/wip/expansion19-preparation",
             "origin/wip/expansion20-preparation", "origin/wip/expansion21-preparation"]
_REF_FILES = {}


def path_exists(p):
    """True if the path is here or on an integration branch; None when it is not here and some of those branches are
    not available in this checkout (a shallow CI clone): then it cannot be decided and is not reported as an error."""
    if (REPO / p).exists():
        return True
    missing_ref = False
    for ref in PATH_REFS:
        if ref not in _REF_FILES:
            out = subprocess.run(["git", "-C", str(REPO), "ls-tree", "-r", "--name-only", ref], capture_output=True, text=True)
            _REF_FILES[ref] = set(out.stdout.split()) if out.returncode == 0 else None
        if _REF_FILES[ref] is None:
            missing_ref = True
        elif p in _REF_FILES[ref]:
            return True
    return None if missing_ref else False


# ------------------------------------------------------------------ the v1 -> v2 mapping (also reads old registers)
def migrate_entry(r, date=None, why=None):
    """An mml-requirements/1 entry as an mml-requirements/2 entry. Conservative: nothing is promoted beyond what the
    v1 status and its recorded evidence say; the v1 status is kept in migrated_from_status."""
    r = dict(r)
    if "status" not in r:
        return r
    v1 = r.pop("status")
    r["migrated_from_status"] = v1
    kind = r.get("kind")
    if kind == "decision":
        r["disposition"] = {"BLOCKED": "OPEN", "UNKNOWN — INVESTIGATION REQUIRED": "OPEN", "SUPERSEDED": "SUPERSEDED",
                            "CANCELED BY OWNER": "SUPERSEDED", "DEFERRED": "DEFERRED"}.get(v1, "APPROVED")
        r.setdefault("blocks_implementation", False)
    else:
        closed = v1 in ("SUPERSEDED", "CANCELED BY OWNER")
        if kind == "rule":
            r["approval_status"] = "SUPERSEDED" if v1 == "SUPERSEDED" else "OWNER APPROVED"
        elif kind == "rejected" or v1 == "CANCELED BY OWNER":
            r["approval_status"] = "REJECTED"
        elif v1 == "SUPERSEDED":
            r["approval_status"] = "SUPERSEDED"
        elif kind in ("proposal", "idea"):
            r["approval_status"] = "PROPOSED"
        elif v1 == "DEFERRED":
            r["approval_status"] = "DEFERRED"
        elif v1 == "UNKNOWN — INVESTIGATION REQUIRED":
            r["approval_status"] = "OWNER DECISION REQUIRED"
        else:
            r["approval_status"] = "OWNER APPROVED"
        done = v1 in ("IMPLEMENTED — TESTING REQUIRED", "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED", "COMPLETE AND VERIFIED")
        if kind == "rule" or closed:
            impl = "NOT APPLICABLE"
        elif done:
            if r.get("integrated_in"):
                impl = "INTEGRATED"
            elif r.get("task_branches") or (r.get("target_build") in ("18", "19", "multiplayer") and v1 != "COMPLETE AND VERIFIED"):
                impl = "IMPLEMENTED ON TASK BRANCH"
            else:
                impl = "INTEGRATED"            # a released build's record: v1 required evidence for it
                r.setdefault("legacy_evidence", "v1 status %s with its recorded evidence (implementation, tests or commits)" % v1)
        else:
            impl = "NOT STARTED" if (kind in ("proposal", "idea") and v1 == "BLOCKED") else {"ACTIVE DEVELOPMENT": "IN DEVELOPMENT", "PARTIALLY IMPLEMENTED": "PARTIALLY IMPLEMENTED",
                    "BLOCKED": "IMPLEMENTATION BLOCKED"}.get(v1, "NOT STARTED")
        r["implementation_status"] = impl
        if kind == "rule" or closed:
            ver = "NOT APPLICABLE"
        elif v1 == "COMPLETE AND VERIFIED":
            ver = "OWNER PLAYTESTED" if r.get("playtest_done") else "INTEGRATION VERIFIED"
        elif v1 == "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED":
            ver = "TARGETED TESTS PASSED"
        elif v1 in ("IMPLEMENTED — TESTING REQUIRED", "PARTIALLY IMPLEMENTED") and str(r.get("tests") or "").strip():
            ver = "TARGETED TESTS PASSED"
        else:
            ver = "NOT TESTED"
        r["verification_status"] = ver
        if v1 == "COMPLETE AND VERIFIED" and not str(r.get("tests") or "").strip():
            r.setdefault("legacy_evidence", "v1 COMPLETE AND VERIFIED with its recorded evidence (implementation or commits)")
        if kind == "rule" or closed or r["approval_status"] in ("DEFERRED", "PROPOSED", "REJECTED"):
            rel = "NOT APPLICABLE"
        elif v1 == "COMPLETE AND VERIFIED":
            released = [x for x in r.get("integrated_in") or [] if "release" in x]
            rel = "RELEASED" if released or r.get("target_build") in ("15", "16", "17") else (
                "NOT READY" if r.get("target_build") in ("18", "19") else "UNKNOWN")
        else:
            rel = "NOT READY"
        r["release_status"] = rel
        r["completion"] = "CLOSED" if closed or kind == "rejected" else ("COMPLETE" if v1 == "COMPLETE AND VERIFIED" else "OPEN")
        if kind == "rule" and v1 != "SUPERSEDED":
            r["completion"] = "COMPLETE"
    if date:
        r.setdefault("history", []).append({"date": date, "change": "schema v2: %s -> %s" % (v1, summary(r)), "why": why or "schema migration"})
    return r


def summary(r):
    if r.get("kind") == "decision":
        return "disposition %s" % r.get("disposition")
    return "approval %s; implementation %s; verification %s; release %s; %s" % (
        r.get("approval_status"), r.get("implementation_status"), r.get("verification_status"), r.get("release_status"), r.get("completion"))


def load(text):
    d = json.loads(text)
    if d.get("format") == "mml-requirements/1":
        d = {"format": FORMAT, "builds": BUILDS_DEFAULT, "requirements": [migrate_entry(r) for r in d["requirements"]],
             "previous_paths": d.get("previous_paths", [])}
    if d.get("format") != FORMAT:
        raise ValueError("not an mml-requirements register")
    return d


def is_open(r):
    return r.get("completion", "OPEN") == "OPEN" if r.get("kind") != "decision" else r.get("disposition") in ("OPEN", "REOPENED", "PROVISIONAL")


def in_scope(r):
    """Approved work that counts toward its build (not an umbrella, not deferred, superseded or rejected)."""
    return (r.get("kind") == "approved" and not r.get("umbrella") and
            r.get("approval_status") in ("OWNER APPROVED", "OWNER DECISION REQUIRED"))


# ------------------------------------------------------------------ validation
def validate(d, check_docs=True):
    errors = []
    reqs = d.get("requirements", [])
    builds = d.get("builds") or BUILDS_DEFAULT
    by_id, aliases = {}, {}
    for r in reqs:
        rid = r.get("id", "")
        if not ID_RE.match(rid):
            errors.append("%s: id is not of the form PREFIX-NUMBER" % rid)
        if rid in by_id:
            errors.append("%s: duplicate id" % rid)
        by_id[rid] = r
    for r in reqs:
        for a in r.get("aliases") or []:
            if a in aliases:
                errors.append("%s: alias %s is also an alias of %s (conflicting canonical records)" % (r["id"], a, aliases[a]))
            aliases[a] = r["id"]
    for a, owner in aliases.items():
        if a in by_id:
            errors.append("%s: alias %s is itself a record's id" % (owner, a))
    for r in reqs:
        rid, kind = r.get("id"), r.get("kind")
        if "status" in r:
            errors.append("%s: v1 'status' field present; use the v2 dimensions (docs/requirements/SCHEMA.md)" % rid)
        if kind not in KINDS:
            errors.append("%s: unknown kind %r" % (rid, kind))
            continue
        for f in ("title", "source"):
            if not str(r.get(f) or "").strip():
                errors.append("%s: no %s" % (rid, f))
        if not r.get("history"):
            errors.append("%s: no history (who entered it, when, why)" % rid)
        t = r.get("target_build")
        if t not in TARGETS and not (t in (None, "") and not is_open(r)) and kind != "rule":
            errors.append("%s: target_build %r is not one of %s" % (rid, t, ", ".join(TARGETS)))
        for f in REF_LISTS:
            for x in r.get(f) or []:
                if x not in by_id:
                    errors.append("%s: %s names %s, which is not in the register" % (rid, f, x))
        for f in ("parent", "superseded_by", "supersedes"):
            if r.get(f) and r[f] not in by_id:
                errors.append("%s: %s %s is not in the register" % (rid, f, r[f]))
        if kind == "decision":
            errors += _decision_errors(r)
        else:
            errors += _requirement_errors(r, builds)
        if check_docs:
            for f in sorted(k for k in r if k != "history"):
                for m in DOC_RE.findall(json.dumps(r[f], ensure_ascii=False)):
                    if path_exists(m) is False:
                        errors.append("%s: %s names %s, which exists neither here nor on an integration branch" % (rid, f, m))
    for a in ANCHORS:
        if a not in by_id:
            errors.append("%s: the roadmap names it, but it is not in the register" % a)
        elif a.startswith("EXP-") and not DOC_RE.search(str(by_id[a].get("source") or "")):
            errors.append("%s: an expansion must name its specification document in its source" % a)
    if check_docs:
        errors += memory_errors(d)
    for r in reqs:
        seen, p = set(), r.get("parent")
        while p:
            if p in seen:
                errors.append("%s: parent chain loops" % r["id"])
                break
            seen.add(p)
            p = by_id.get(p, {}).get("parent")
    return errors


def _decision_errors(r):
    e, rid, disp = [], r["id"], r.get("disposition")
    if disp not in DISPOSITION:
        e.append("%s: unknown disposition %r" % (rid, disp))
    answered = str(r.get("owner_answer") or "").strip() or str(r.get("owner_wording") or "").strip()
    if disp in ("APPROVED", "PROVISIONAL") and not answered:
        e.append("%s: a decision is %s only with the owner's words (owner_answer)" % (rid, disp))
    if disp == "SUPERSEDED" and not r.get("superseded_by"):
        e.append("%s: SUPERSEDED needs superseded_by" % rid)
    if disp != "SUPERSEDED" and r.get("superseded_by"):
        e.append("%s: superseded_by is set but the disposition is %s" % (rid, disp))
    if not isinstance(r.get("blocks_implementation", False), bool):
        e.append("%s: blocks_implementation must be true or false" % rid)
    return e


def _requirement_errors(r, builds):
    e, rid, kind = [], r["id"], r["kind"]
    ap, im, ve, rl, co = (r.get("approval_status"), r.get("implementation_status"), r.get("verification_status"),
                          r.get("release_status"), r.get("completion"))
    for name, v, allowed in (("approval_status", ap, APPROVAL), ("implementation_status", im, IMPLEMENTATION),
                             ("verification_status", ve, VERIFICATION), ("release_status", rl, RELEASE), ("completion", co, COMPLETION)):
        if v not in allowed:
            e.append("%s: %s %r is not one of %s" % (rid, name, v, ", ".join(allowed)))
    for name, v, allowed in (("design", r.get("design"), DESIGN), ("effort", r.get("effort"), EFFORT)):
        if v is not None and v not in allowed:
            e.append("%s: %s %r is not one of %s" % (rid, name, v, ", ".join(allowed)))
    if kind == "approved" and ap == "OWNER APPROVED":
        if not str(r.get("approval") or "").strip():
            e.append("%s: an approved requirement needs its approval evidence" % rid)
        if not r.get("acceptance"):
            e.append("%s: approved work needs acceptance criteria" % rid)
    acc = r.get("acceptance")
    if acc and (not isinstance(acc, list) or (len(acc) > 1 and all(len(str(a).strip()) <= 1 for a in acc))):
        e.append("%s: acceptance must be a list of criteria, not a string or its single characters" % rid)
    if kind in ("proposal", "idea") and ap == "OWNER APPROVED":
        e.append("%s: a %s cannot be OWNER APPROVED (make it kind approved with the owner's approval)" % (rid, kind))
    # contradictions between the dimensions
    if ap in ("SUPERSEDED", "REJECTED") and co != "CLOSED":
        e.append("%s: %s must have completion CLOSED" % (rid, ap))
    if ap == "SUPERSEDED" and not r.get("superseded_by"):
        e.append("%s: SUPERSEDED needs superseded_by naming its replacement" % rid)
    if ap != "SUPERSEDED" and r.get("superseded_by"):
        e.append("%s: superseded_by is set but approval is %s" % (rid, ap))
    if co == "CLOSED" and ap not in ("SUPERSEDED", "REJECTED"):
        e.append("%s: CLOSED is for superseded or rejected records" % rid)
    if co == "COMPLETE" and kind != "rule":
        if im != "INTEGRATED":
            e.append("%s: COMPLETE needs implementation INTEGRATED (is %s)" % (rid, im))
        if VERIFIED_LEVEL.get(ve, -1) < VERIFIED_LEVEL["INTEGRATION VERIFIED"]:
            e.append("%s: COMPLETE needs verification INTEGRATION VERIFIED or above (is %s)" % (rid, ve))
        if r.get("playtest") and not r.get("playtest_done"):
            e.append("%s: COMPLETE with an open playtest requirement %s" % (rid, r["playtest"]))
    if rl in ("RELEASE CANDIDATE", "RELEASE READY", "RELEASED") and ap != "OWNER APPROVED":
        e.append("%s: %s but not owner approved (%s)" % (rid, rl, ap))
    if rl == "RELEASED" and co != "COMPLETE":
        e.append("%s: RELEASED but not COMPLETE" % rid)
    if rl in ("RELEASE CANDIDATE", "RELEASE READY") and im != "INTEGRATED":
        e.append("%s: %s needs integrated code" % (rid, rl))
    # evidence
    if im == "INTEGRATED" and not (r.get("integrated_in") or r.get("commits") or r.get("legacy_evidence")):
        e.append("%s: INTEGRATED without integration evidence (integrated_in or commits)" % rid)
    if im == "IN DEVELOPMENT" and not (str(r.get("assigned_worker") or "").strip() and str(r.get("branch") or "").strip()):
        e.append("%s: IN DEVELOPMENT needs assigned_worker and branch (otherwise it is READY, PARTIALLY IMPLEMENTED or NOT STARTED)" % rid)
    lvl = VERIFIED_LEVEL.get(ve, -1)
    if lvl >= VERIFIED_LEVEL["TARGETED TESTS PASSED"] and not (str(r.get("tests") or "").strip() or r.get("legacy_evidence")):
        e.append("%s: verification %s without test evidence (tests)" % (rid, ve))
    if ve == "INTEGRATION VERIFIED" and im != "INTEGRATED" and co != "COMPLETE":
        e.append("%s: INTEGRATION VERIFIED but not integrated (%s)" % (rid, im))
    if lvl >= VERIFIED_LEVEL["GAMEPLAY VERIFIED"] and not (r.get("playtest_done") or r.get("gameplay_verification")):
        e.append("%s: %s without a gameplay or playtest record" % (rid, ve))
    if ve == "VERIFICATION FAILED" and not r.get("known_defects"):
        e.append("%s: VERIFICATION FAILED must name the defect (known_defects)" % rid)
    # builds
    t = r.get("target_build")
    if t in builds and not builds[t].get("implementation_authorized") and im not in ("NOT STARTED", "READY", "IMPLEMENTATION BLOCKED", "NOT APPLICABLE"):
        e.append("%s: Build %s is not authorized for implementation, but the requirement is %s" % (rid, t, im))
    if r.get("design") == "OWNER DECISION REQUIRED" and not r.get("decisions"):
        e.append("%s: design OWNER DECISION REQUIRED must name the open decision (decisions)" % rid)
    return e


def memory_errors(d):
    errors = []
    for f in (MEMORY, STATE):
        if not f.exists():
            errors.append("%s is missing (the project memory, MEM-01)" % f.relative_to(REPO))
            continue
        for m in sorted(set(LINK_RE.findall(f.read_text()))):
            path = m.rstrip("/.,;:)")
            generated = {str(reconciliation_path(bp).relative_to(REPO)) for bp in BASELINES} | {"docs/requirements/views"} | {
                "docs/requirements/views/%s.md" % n for n in ("STATUS", "DECISIONS", "BACKLOG", "QUEUES", "BUILD_18", "BUILD_19", "BUILD_20", "BUILD_21", "BUILD_22", "BUILD_23", "BUILD_24", "BUILD_25")}
            if not (REPO / path).exists() and not list(REPO.glob(path)) and path not in generated:
                errors.append("%s names %s, which does not exist" % (f.relative_to(REPO), path))
    if STATE.exists():
        text = STATE.read_text()
        for r in d.get("requirements", []):
            if r.get("implementation_status") == "IN DEVELOPMENT" and not re.search(r"\b%s\b" % re.escape(r["id"]), text):
                errors.append("%s is IN DEVELOPMENT but docs/CURRENT_DEVELOPMENT_STATE.md does not mention it" % r["id"])
    return errors


# ------------------------------------------------------------------ baselines and comparison with older registers
BASELINES = sorted((REPO / "docs" / "requirements").glob("baseline_*.json"))
DIMS = ("approval_status", "implementation_status", "verification_status", "release_status", "completion", "disposition")


def _dims(r):
    return tuple(r.get(k) for k in DIMS)


def baseline_errors(d, b):
    errors = []
    by = {r["id"]: r for r in d.get("requirements", [])}
    for group in ("open", "closed_approved", "other"):
        for rid, was in sorted(b.get(group, {}).items()):
            r = by.get(rid)
            if r is None:
                errors.append("%s: in the %s baseline (%s), now missing from the register" % (rid, b.get("date"), group))
                continue
            then = migrate_entry({"kind": r.get("kind"), "status": was.get("status"), "target_build": was.get("target_build")})
            changed = (was.get("kind") not in (None, r.get("kind")) or
                       (was.get("target_build") is not None and was.get("target_build") != r.get("target_build")) or
                       (was.get("status") is not None and r.get("migrated_from_status") != was.get("status")
                        and _dims(then) != _dims(r)))
            if changed and len(r.get("history") or []) <= was.get("history", 0):
                errors.append("%s: changed since the %s baseline with no history entry saying why" % (rid, b.get("date")))
    return errors


def reconciliation_path(bpath):
    return bpath.parent / ("RECONCILIATION_%s.md" % bpath.stem.split("_", 1)[1])


def state_label(r):
    if r.get("kind") == "decision":
        return r.get("disposition", "")
    return "%s / %s / %s" % (r.get("implementation_status"), r.get("verification_status"), r.get("completion"))


def render_reconciliation(d, b):
    by = {r["id"]: r for r in d["requirements"]}
    op, cl = b["open"], b["closed_approved"]
    now_closed = [i for i in op if i in by and not is_open(by[i])]
    moved = [i for i in op if i in by and by[i].get("target_build") != op[i].get("target_build")]
    reopened = [i for i in cl if i in by and is_open(by[i]) and by[i].get("kind") != "rule"]
    new = [r for r in d["requirements"] if r["id"] not in op and r["id"] not in cl and r["id"] not in b.get("other", {})]
    open_now = [r for r in d["requirements"] if r["kind"] != "rule" and is_open(r)]
    lines = ["# Requirements reconciliation of %s (baseline `%s`)" % (b["date"], b["commit"]), "",
             "Generated by `python3 tools/check_requirements.py --write` from the frozen baseline",
             "`docs/requirements/%s` and the current register; do not edit. The validator fails if any baseline" % ("baseline_%s.json" % b["date"]),
             "entry leaves the register or changes without a history entry. Statuses are shown as implementation /",
             "verification / completion (decisions: disposition); see docs/requirements/SCHEMA.md.", "",
             "| | Baseline | Now |", "|---|---|---|",
             "| Open entries (rules excluded) | %d | %d still open, %d closed since |" % (len(op), len(op) - len(now_closed), len(now_closed)),
             "| Closed approved (complete, superseded, canceled) | %d | %d still closed, %d reopened |" % (len(cl), len(cl) - len(reopened), len(reopened)),
             "| Other entries (rules; closed decisions and proposals) | %d | |" % len(b.get("other", {})),
             "| Entries added since | | %d (%d of them still open) |" % (len(new), sum(1 for r in new if is_open(r))),
             "| **Open entries now** (rules excluded) | | **%d** |" % len(open_now),
             "| Open entries moved to another build | | %d |" % len(moved), ""]

    def table(title, ids):
        out = ["## %s (%d)" % (title, len(ids)), ""]
        if not ids:
            return out + ["None.", ""]
        out += ["| ID | Item | Kind | Baseline status | Baseline build | State now | Build now |", "|---|---|---|---|---|---|---|"]
        for i in sorted(ids):
            r, was = by[i], (op.get(i) or cl.get(i))
            out.append("| %s | %s | %s | %s | %s | %s | %s |" % (i, _cell(r["title"]), r["kind"], was.get("status"), was.get("target_build") or "",
                       state_label(r), r.get("target_build") or ""))
        return out + [""]
    lines += table("Closed since the baseline", now_closed)
    lines += table("Moved to another build since the baseline", moved)
    lines += table("Reopened since the baseline", reopened)
    lines += ["## Added since the baseline (%d)" % len(new), "", "| ID | Item | Kind | State | Build |", "|---|---|---|---|---|"]
    lines += ["| %s | %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), r["kind"], state_label(r), r.get("target_build") or "")
              for r in sorted(new, key=lambda r: r["id"])]
    lines += ["", "The current state by build is in `docs/requirements/views/`.", ""]
    return "\n".join(lines)


def compare(old, new):
    """Records lost or changed without a record since `old` (both as v2 dicts; v1 registers are read through load)."""
    errors = []
    new_by = {r["id"]: r for r in new.get("requirements", [])}
    for o in old.get("requirements", []):
        n = new_by.get(o["id"])
        if n is None:
            errors.append("%s (%s) disappeared from the register: records are never deleted; close it (CLOSED with "
                          "superseded_by or REJECTED with the owner's words) instead" % (o["id"], o.get("kind")))
            continue
        grew = len(n.get("history") or []) > len(o.get("history") or [])
        if (_dims(o) != _dims(n) or o.get("kind") != n.get("kind")) and not grew:
            errors.append("%s: %s -> %s with no new history entry saying why" % (o["id"], state_label(o), state_label(n)))
        if o.get("target_build") and o.get("target_build") != n.get("target_build") and not grew:
            errors.append("%s: moved from build %s to %s with no new history entry saying why" % (
                o["id"], o.get("target_build"), n.get("target_build")))
        if o.get("kind") == "decision" and n.get("kind") != "decision" and not str(n.get("owner_answer") or "").strip():
            errors.append("%s: an owner decision became %s without the owner's answer (owner_answer)" % (o["id"], n.get("kind")))
        if o.get("kind") == "decision" and o.get("disposition") == "OPEN" and n.get("disposition") in ("APPROVED", "PROVISIONAL") \
                and not str(n.get("owner_answer") or "").strip():
            errors.append("%s: an open owner decision was answered without the owner's words" % o["id"])
        if len(n.get("history") or []) < len(o.get("history") or []):
            errors.append("%s: history entries were removed" % o["id"])
    return errors


def at_ref(ref, d):
    for path in [REGISTER] + list(d.get("previous_paths", [])):
        r = subprocess.run(["git", "-C", str(REPO), "show", "%s:%s" % (ref, path)], capture_output=True, text=True)
        if r.returncode == 0:
            return load(r.stdout)
    return None


# ------------------------------------------------------------------ the generated ledger (full listing)
def render(d):
    reqs = d["requirements"]
    lines = ["# Development ledger: the requirements register", "",
             "Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`; do not edit.",
             "The register is the one manually maintained list (schema: `docs/requirements/SCHEMA.md`); progress by build is in",
             "`docs/requirements/views/STATUS.md`. Proposals, ideas and open owner decisions are never counted as approved work.", ""]
    for k in ("approved", "proposal", "idea", "rule", "rejected"):
        rows = sorted([r for r in reqs if r["kind"] == k], key=lambda r: r["id"])
        if not rows:
            continue
        lines += ["## %s (%d)" % (KINDS[k], len(rows)), "",
                  "| ID | Item | Build | Approval | Implementation | Verification | Release | Completion |", "|---|---|---|---|---|---|---|---|"]
        for r in rows:
            lines.append("| %s | %s | %s | %s | %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), r.get("target_build") or "",
                         r.get("approval_status"), r.get("implementation_status"), r.get("verification_status"),
                         r.get("release_status"), r.get("completion")))
        lines.append("")
    rows = sorted([r for r in reqs if r["kind"] == "decision"], key=lambda r: r["id"])
    lines += ["## Owner decisions (%d)" % len(rows), "", "| ID | Question | Build | Disposition | Blocks implementation |", "|---|---|---|---|---|"]
    for r in rows:
        lines.append("| %s | %s | %s | %s | %s |" % (r["id"], _cell(r["title"]), r.get("target_build") or "", r.get("disposition"),
                                                    "yes" if r.get("blocks_implementation") else ""))
    lines.append("")
    return "\n".join(lines)


def _cell(s):
    return str(s).replace("|", "/").replace("\n", " ")


def outputs(d):
    import requirements_report as rr
    out = [(LEDGER, render(d) + "\n")]
    for path, text in rr.views(d).items():
        out.append((path, text))
    for bp in BASELINES:
        out.append((reconciliation_path(bp), render_reconciliation(d, json.loads(bp.read_text()))))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--write", action="store_true", help="regenerate the ledger and the views")
    ap.add_argument("--against", metavar="REF", help="also check nothing was lost since this git commit or branch")
    ap.add_argument("--register", default=str(REPO / REGISTER), help=argparse.SUPPRESS)
    a = ap.parse_args()
    sys.path.insert(0, str(REPO / "tools"))
    d = load(Path(a.register).read_text())
    errors = validate(d)
    if a.against:
        old = at_ref(a.against, d)
        if old is None:
            print("note: no register at %s to compare with" % a.against)
        else:
            errors += compare(old, d)
    for bp in BASELINES:
        errors += baseline_errors(d, json.loads(bp.read_text()))
    outs = outputs(d)
    if a.write and not errors:
        for path, text in outs:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
    elif not errors:
        for path, text in outs:
            if not path.exists() or path.read_text() != text:
                errors.append("%s is out of date: run python3 tools/check_requirements.py --write" % path.relative_to(REPO))
    for e in errors:
        print("problem:", e)
    reqs = d["requirements"]
    print("%d records (%d approved, %d decisions), %d open approved, %d open decisions, %d problems" % (
        len(reqs), sum(1 for r in reqs if r["kind"] == "approved"), sum(1 for r in reqs if r["kind"] == "decision"),
        sum(1 for r in reqs if r["kind"] == "approved" and is_open(r)),
        sum(1 for r in reqs if r["kind"] == "decision" and is_open(r)), len(errors)))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
