"""One validation report for one commit, from every required group's evidence (B25R1 CI architecture,
docs/ci/CI_ARCHITECTURE_B25R1.md).

It reads what the runs left (artifacts, downloaded) and what GitHub says about the runs (`gh run view ID --json
headSha,status,conclusion,jobs`), and writes one summary (mml-ci-validation/1 and Markdown): the commit, each group, pass or
fail, the simulated days reached, the conservation and determinism results, missing or invalid evidence, the wall-clock and
the runner minutes. It FAILS (exit 1) when a required source is missing, names another commit, or any of its jobs was
cancelled, skipped, timed out or failed: a green part from another commit never counts.

Sources (each optional; --require names those that must be present):

  --tests DIR      the Tests run's ci-report-<run>-<attempt>-shard<N> artifacts (each with ci-report.json and shard.json)
  --gate DIR       the simulation gate's `sim-gate` artifact (gate.json, and parts.json when it ran split)
  --campaign DIR   a flight recorder campaign's fr-seed*-results and fr-living-world-seed* artifacts
  --meta NAME=FILE that source's run, as `gh run view ID --json headSha,status,conclusion,jobs` printed it

  python3 tools/ci_consolidate.py --sha SHA --tests dl/tests --meta tests=tests.json --require tests \\
      --json out/validation.json --markdown "$GITHUB_STEP_SUMMARY"

The logical groups (world and navigation, economy and conservation, ...) only sort the Tests suites for the reader; the
suites are placed on runners by measured time (tools/ci_plan.py), not by group. Standard library only.
"""
import argparse
import datetime
import glob
import json
import os
import sys

FORMAT = "mml-ci-validation/1"
# the owner's logical groups (2026-11-04), by the suite's name; the first group a keyword matches wins
GROUPS = [
    ("save, load, migration and determinism", ["save", "migration", "determin", "recorder", "continuity", "identity", "journal", "net_", "multiplayer"]),
    ("water, hamlets and settlements", ["water", "hamlet", "settlement", "regional", "region_sim", "envoy", "intel", "seed_traveler", "regions_"]),
    ("homesteading, construction and outlaws", ["homestead", "home", "housing", "construct", "outlaw", "bandit", "refuge", "campfire", "property",
                                                 "furniture", "runaway", "recruit", "chests", "lockpick"]),
    ("presence, crowds and animals", ["presence", "crowd", "wildlife", "herd", "horse", "ecology", "fauna", "animal", "folk"]),
    ("economy and conservation", ["econom", "le0", "le02", "market", "business", "till", "credit", "tax", "treasury", "reserve", "conservation",
                                  "contract", "trade", "stall", "luxury", "exploit", "od16", "recf1", "region_demand", "craft", "courier",
                                  "wear", "leak", "farm", "crop", "feast", "chapel", "services", "capability", "profile", "parity", "experience"]),
    ("world, maps and navigation", ["overworld", "atlas", "region_geography", "journey", "travel", "road", "terrain", "tree", "world",
                                    "pursuit", "underground", "quarry", "openpit", "prospect", "discovery", "mine", "stone", "decay"]),
]
BAD_JOB = ("cancelled", "skipped", "timed_out", "failure", "action_required", "stale", "startup_failure", "neutral", None, "")


def logical_group(name):
    n = name.lower()
    for g, keys in GROUPS:
        if any(k in n for k in keys):
            return g
    return "interface, people, judgment and other systems"


def load(path, default=None):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def ts(s):
    return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ") if s else None


def job_timing(meta, skip=("report",)):
    """(wall-clock minutes, runner minutes, problems) from a run's jobs; this report's own job is left out."""
    jobs = [j for j in (meta or {}).get("jobs", []) if not any(j.get("name", "").startswith(s) for s in skip)]
    probs, starts, ends, runner = [], [], [], 0.0
    for j in jobs:
        c = j.get("conclusion")
        if c in BAD_JOB:
            probs.append("job '%s': %s" % (j.get("name"), c or j.get("status") or "not finished"))
        a, b = ts(j.get("startedAt")), ts(j.get("completedAt"))
        if a and b and b >= a:
            starts.append(a)
            ends.append(b)
            runner += (b - a).total_seconds() / 60.0
    wall = (max(ends) - min(starts)).total_seconds() / 60.0 if starts else None
    return wall, runner, probs, len(jobs)


def check_meta(name, meta, sha, problems):
    if meta is None:
        return
    if meta.get("headSha") and meta["headSha"] != sha:
        problems.append("%s: the run is of commit %s, not %s" % (name, meta["headSha"], sha))


def tests_source(d, sha, meta):
    src = {"present": False, "result": "missing", "problems": [], "groups": {}, "shards": 0, "suites": 0, "failed": [],
           "sim_10_day": None}
    dirs = sorted(glob.glob(os.path.join(d, "ci-report-*-shard*"))) if d else []
    if not dirs:
        src["problems"].append("no Tests shard artifacts")
        return src
    src["present"] = True
    mans, reps = {}, {}
    for p in dirs:
        man, rep = load(os.path.join(p, "shard.json")), load(os.path.join(p, "ci-report.json"))
        k = int(man["shard"] if man else p.rsplit("shard", 1)[1])
        if man is None:
            src["problems"].append("%s: no shard manifest" % os.path.basename(p))
        if rep is None:
            src["problems"].append("%s: no ci-report.json" % os.path.basename(p))
        mans[k], reps[k] = man, rep
    good = [m for m in mans.values() if m]
    n = good[0]["shards"] if good else 0
    src["shards"] = n
    for k in range(n):
        if k not in mans:
            src["problems"].append("shard %d: no artifact (the job did not finish)" % k)
    if len({m["list_sha256"] for m in good}) > 1:
        src["problems"].append("the shards ran different suite lists")
    for k, m in mans.items():
        rep = reps.get(k)
        if m and m.get("commit") != sha:
            src["problems"].append("shard %s planned on commit %s" % (k, m.get("commit")))
        if rep is None:
            continue
        if rep["identification"].get("commit") != sha:
            src["problems"].append("shard %s reports commit %s" % (k, rep["identification"].get("commit")))
        if rep["outcome"] != "TESTED":
            src["problems"].append("shard %s: %s" % (k, rep["outcome"]))
        for miss in rep.get("missing_evidence", []):
            src["problems"].append("shard %s: %s" % (k, miss))
        ran = {}
        for s in rep["suites"]:
            ran.setdefault((s["group"], s["name"]), []).append(s)
            if s["group"] == "game":
                g = src["groups"].setdefault(logical_group(s["name"]), {"suites": 0, "passed": 0, "failed": 0})
                g["suites"] += 1
                g["passed" if s["status"] == "passed" else "failed"] += 1
            if s["status"] != "passed":
                src["failed"].append("%s (%s, shard %s)" % (s["name"], s["status"], k))
        src["suites"] += len(rep["suites"])
        if m:
            want = {}
            for name in m["assigned"]:
                want[name] = want.get(name, 0) + 1
            for name, c in want.items():
                if len(ran.get(("game", name), [])) != c:
                    src["problems"].append("shard %s: suite %s assigned %d time(s), ran %d" % (k, name, c, len(ran.get(("game", name), []))))
    if good:
        every = sorted(good[0]["list"])
        assigned = sorted(x for m in good for x in m["assigned"])
        if len(good) == n and assigned != every:
            src["problems"].append("the shards' assignments do not cover the suite list exactly once")
    for p in dirs:
        sim = load(os.path.join(p, "sim.json"))
        if sim and sim.get("samples"):
            last = sim["samples"][-1]
            src["sim_10_day"] = {"days_reached": sim.get("reached", last.get("day")), "currency_leak": (last.get("currency") or {}).get("leak"),
                                 "item_leaks": (last.get("ledger") or {}).get("items")}
    wall, runner, probs, njobs = job_timing(meta)
    src["problems"] += probs
    src.update({"wall_minutes": wall, "runner_minutes": runner, "jobs": njobs})
    src["result"] = "pass" if not src["problems"] and not src["failed"] else "fail"
    return src


def gate_source(d, sha, meta):
    src = {"present": False, "result": "missing", "problems": []}
    g = load(os.path.join(d, "gate.json")) if d else None
    if g is None:
        src["problems"].append("no gate.json")
        return src
    src["present"] = True
    if g.get("commit") != sha:
        src["problems"].append("the gate ran commit %s" % g.get("commit"))
    if g.get("subset"):
        src["problems"].append("a subset (--only / --short): not a gate")
    parts = load(os.path.join(d, "parts.json"))
    if parts and parts.get("problems"):
        src["problems"] += ["parts: %s" % p for p in parts["problems"]]
    blocking = [f for f in g.get("findings", []) if f.get("blocking")]
    src["blocking_findings"] = len(blocking)
    src["blocking"] = ["%s: %s" % (f.get("run"), f.get("description")) for f in blocking[:20]]
    src["days"] = {r["run"]: "%s of %s" % (r.get("reached"), r.get("days")) for r in g.get("runs", [])}
    src["conservation"] = "broken" if any("conservation" in f.get("description", "") or "coins created or lost" in f.get("description", "") for f in blocking) else "held"
    det = [h for h in g.get("history", []) if str(h.get("comparison", "")).startswith("determinism")]
    src["determinism"] = {h["comparison"]: h["verdict"] for h in det} or "not compared"
    src["gate_result"] = g.get("result")
    wall, runner, probs, njobs = job_timing(meta)
    src["problems"] += probs
    src.update({"wall_minutes": wall, "runner_minutes": runner, "jobs": njobs})
    src["result"] = "pass" if not src["problems"] and g.get("result") == "PASS" else "fail"
    return src


def campaign_source(d, sha, meta, days):
    src = {"present": False, "result": "missing", "problems": [], "seeds": {}}
    sums = sorted(glob.glob(os.path.join(d, "fr-seed*-results", "summary.json"))) if d else []
    if not sums:
        src["problems"].append("no fr-seed*-results summaries")
        return src
    src["present"] = True
    for p in sums:
        s = load(p, {})
        tag = os.path.basename(os.path.dirname(p))[len("fr-seed"):-len("-results")]
        if s.get("commit") != sha:
            src["problems"].append("seed %s ran commit %s" % (tag, s.get("commit")))
        if days and s.get("days_reached") != days:
            src["problems"].append("seed %s reached day %s of %s (%s)" % (tag, s.get("days_reached"), days, s.get("stop_reason")))
        if s.get("confirmed_defects"):
            src["problems"].append("seed %s: %s confirmed defects" % (tag, s.get("confirmed_defects")))
        if s.get("archive_ok") is not True:
            src["problems"].append("seed %s: archive checks %s" % (tag, s.get("archive_ok")))
        src["seeds"][tag] = {k: s.get(k) for k in ("days_reached", "days_requested", "stop_reason", "severity_counts", "confirmed_defects", "archive_ok")}
    for p in sorted(glob.glob(os.path.join(d, "fr-living-world-seed*", "lives.json"))):
        lv = load(p, {})
        seed = os.path.basename(os.path.dirname(p))[len("fr-living-world-seed"):]
        det = ((lv.get("evidence") or {}).get("determinism")) or {}
        ident = det.get("identical")
        src["seeds"].setdefault(seed, {})["determinism_identical"] = ident
        if ident is not True:
            src["problems"].append("seed %s: the twin runs %s" % (seed, "differ from day %s" % det.get("first_stream_difference") if det else "were not compared"))
    twins = [k for k in src["seeds"] if k.endswith("-twin")]
    for k in list(src["seeds"]):
        if not k.endswith("-twin") and twins and "determinism_identical" not in src["seeds"][k]:
            src["problems"].append("seed %s: no determinism comparison (living-world report missing)" % k)
    wall, runner, probs, njobs = job_timing(meta)
    src["problems"] += probs
    src.update({"wall_minutes": wall, "runner_minutes": runner, "jobs": njobs})
    src["result"] = "pass" if not src["problems"] else "fail"
    return src


def render(rep):
    L = ["## Validation report: %s" % rep["result"].upper(), "", "- Commit: `%s`" % rep["sha"],
         "- Wall-clock (longest source): %s min; runner minutes (all sources): %.0f" % (
             "%.0f" % rep["wall_minutes"] if rep["wall_minutes"] is not None else "unknown", rep["runner_minutes"]), ""]
    L += ["| source | required | result | wall min | runner min | jobs | problems |", "|---|---|---|---|---|---|---|"]
    for k, s in rep["sources"].items():
        L.append("| %s | %s | %s | %s | %s | %s | %d |" % (k, "yes" if s["required"] else "no", s["result"],
                 "%.0f" % s["wall_minutes"] if s.get("wall_minutes") is not None else "-", "%.0f" % s["runner_minutes"] if s.get("runner_minutes") else "-",
                 s.get("jobs", "-"), len(s["problems"])))
    t = rep["sources"].get("tests")
    if t and t["present"]:
        L += ["", "### Tests by logical group", "", "| group | suites | passed | failed |", "|---|---|---|---|"]
        for g, c in sorted(t["groups"].items()):
            L.append("| %s | %d | %d | %d |" % (g, c["suites"], c["passed"], c["failed"]))
        if t.get("sim_10_day"):
            s = t["sim_10_day"]
            L.append("\n10-day economy run: day %s reached; currency leak %s; item leaks %s." % (s["days_reached"], s["currency_leak"], s["item_leaks"] or "none"))
    g = rep["sources"].get("gate")
    if g and g["present"]:
        L += ["", "### Simulation gate", "", "- Result: %s; blocking findings: %s; conservation: %s" % (g.get("gate_result"), g.get("blocking_findings"), g.get("conservation")),
              "- Determinism: %s" % json.dumps(g.get("determinism")), "- Days: %s" % ", ".join("%s %s" % kv for kv in sorted(g.get("days", {}).items()))]
    c = rep["sources"].get("campaign")
    if c and c["present"]:
        L += ["", "### 365-day campaign", "", "| run | days | stop | confirmed defects | archive ok | determinism |", "|---|---|---|---|---|---|"]
        for k, s in sorted(c["seeds"].items()):
            L.append("| %s | %s of %s | %s | %s | %s | %s |" % (k, s.get("days_reached"), s.get("days_requested"), s.get("stop_reason"), s.get("confirmed_defects"),
                                                         s.get("archive_ok"), s.get("determinism_identical", "-")))
    if rep["problems"]:
        L += ["", "### Missing or invalid evidence, failures", ""] + ["- %s" % p for p in rep["problems"]]
    return "\n".join(L) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--sha", required=True)
    ap.add_argument("--tests", default="")
    ap.add_argument("--gate", default="")
    ap.add_argument("--campaign", default="")
    ap.add_argument("--campaign-days", type=int, default=365)
    ap.add_argument("--meta", action="append", default=[], help="NAME=FILE: gh run view --json headSha,status,conclusion,jobs")
    ap.add_argument("--require", default="", help="comma-separated: tests, gate, campaign")
    ap.add_argument("--json", default="")
    ap.add_argument("--markdown", default="")
    a = ap.parse_args(argv)
    metas = {}
    for m in a.meta:
        k, _, f = m.partition("=")
        metas[k] = load(f)
        if metas[k] is None:
            metas[k] = {"jobs": [], "headSha": None, "unreadable": f}
    required = [r for r in a.require.split(",") if r]
    sources = {}
    if a.tests or "tests" in required:
        sources["tests"] = tests_source(a.tests, a.sha, metas.get("tests"))
    if a.gate or "gate" in required:
        sources["gate"] = gate_source(a.gate, a.sha, metas.get("gate"))
    if a.campaign or "campaign" in required:
        sources["campaign"] = campaign_source(a.campaign, a.sha, metas.get("campaign"), a.campaign_days)
    problems = []
    for k, s in sources.items():
        s["required"] = k in required
        meta = metas.get(k)
        check_meta(k, meta, a.sha, s["problems"])
        if meta and meta.get("unreadable"):
            s["problems"].append("its run record %s could not be read" % meta["unreadable"])
        if s["required"] and meta is None:
            s["problems"].append("no run record (gh run view) to prove its jobs finished")
        s["result"] = "pass" if s["present"] and not s["problems"] and s["result"] == "pass" else ("missing" if not s["present"] else "fail")
        if s["required"] or s["present"]:
            problems += ["%s: %s" % (k, p) for p in s["problems"]] + ["%s: suite failed: %s" % (k, f) for f in s.get("failed", [])]
    walls = [s["wall_minutes"] for s in sources.values() if s.get("wall_minutes") is not None]
    rep = {"format": FORMAT, "sha": a.sha, "generated": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
           "required": required, "sources": sources, "problems": problems,
           "wall_minutes": max(walls) if walls else None, "runner_minutes": sum(s.get("runner_minutes") or 0 for s in sources.values()),
           "result": "pass" if all(sources.get(r, {}).get("result") == "pass" for r in required) and not problems else "fail"}
    if a.json:
        os.makedirs(os.path.dirname(os.path.abspath(a.json)), exist_ok=True)
        with open(a.json, "w") as f:
            json.dump(rep, f, indent=1)
    md = render(rep)
    if a.markdown:
        with open(a.markdown, "a") as f:
            f.write(md)
    print(md)
    return 0 if rep["result"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
