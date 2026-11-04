"""Plan CI work across parallel GitHub runners from measured timings (B25R1 CI architecture, docs/ci/CI_ARCHITECTURE_B25R1.md).

It never changes what runs, only where: every suite of the list and every simulation-gate run is assigned to exactly one
runner, deterministically (the same list, timings and commit give the same plan on every runner).

  tests-shard   One shard's game suites, packed longest-processing-time first from tools/ci_timings.json (unknown suites,
                for example ones just added to the list, go one by one to the least-loaded shard). Shard 0 also runs the
                Python checks and the 10-day economy run, so it starts with their measured time. Writes the shard's list
                (each suite line kept whole, its arguments included) and a manifest (mml-ci-shard/1) the report job checks.

      python3 tools/ci_plan.py tests-shard --list game.txt --shards 8 --shard 3 --out shard.txt --manifest shard.json

  gate-plan     The simulation gate's runs (exactly those tools/sim_suite.py would run on this commit, its rotating seeds
                included) packed into N parts, each part run on its own runner by sim_suite.py --only. A determinism pair
                (a recorded run and its unrecorded twin) stays in one part so the recorder-overhead measure compares runs
                that shared a machine. Prints the matrix as JSON.

      python3 tools/ci_plan.py gate-plan --parts 4 [--jobs 4]

  gate-record   After one part ran: its job results and exit code to <out>/part-<k>.json (the part's own gate.json is a
                subset evaluation and is not kept).

  gate-merge    In the gathering job, with every part's files downloaded into one directory: check that every expected run
                is there exactly once with its output directory, that every part recorded an exit code of 0 or 1 (a
                finding, never a crash or timeout of the tool), and that every part ran this commit; then write the merged
                gate.json that sim_suite.py --reuse evaluates as one whole gate. Exit 1 on anything missing.

      python3 tools/ci_plan.py gate-merge --dir out/sim-gate --plan "$PLAN_JSON"

Standard library only.
"""
import argparse
import contextlib
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TIMINGS = Path(__file__).resolve().parent / "ci_timings.json"
sys.path.insert(0, str(Path(__file__).resolve().parent))
from ci_report import parse_list, suite_name  # noqa: E402


def load_timings(path=TIMINGS):
    with open(path) as f:
        t = json.load(f)
    if t.get("format") != "mml-ci-timings/1":
        sys.exit("%s: not mml-ci-timings/1" % path)
    return t


def git_commit():
    """The checked-out commit (what sim_suite.py and the reports record), else GITHUB_SHA."""
    r = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True)
    return r.stdout.strip() or os.environ.get("GITHUB_SHA", "")


# ------------------------------------------------------------------ tests ----------------------------------------------------
def suite_lines(text):
    """The list's suite lines as written (comments dropped), with the name ci_report.py gives each."""
    out = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if parse_list(line):
            out.append((line, suite_name(parse_list(line)[0])))
    return out


def pack_tests(lines, shards, timings):
    """Shard index for each line: known suites longest first to the least-loaded shard, then unknown ones in list order."""
    tests = timings["tests"]
    unknown_s = timings["defaults"]["unknown_suite_seconds"]
    load = [0.0] * shards
    load[0] = sum(tests.get(k, 0.0) for k in timings["shard0_extra"])
    where = [None] * len(lines)
    known = [i for i, (_, n) in enumerate(lines) if "game/" + n in tests]
    for i in sorted(known, key=lambda i: (-tests["game/" + lines[i][1]], i)):
        s = min(range(shards), key=lambda k: (load[k], k))
        where[i] = s
        load[s] += tests["game/" + lines[i][1]]
    for i, (_, n) in enumerate(lines):
        if where[i] is None:
            s = min(range(shards), key=lambda k: (load[k], k))
            where[i] = s
            load[s] += unknown_s
    return where, load


def cmd_tests_shard(a):
    text = open(a.list).read()
    lines = suite_lines(text)
    if not lines:
        sys.exit("the suite list is empty")
    t = load_timings(a.timings)
    where, load = pack_tests(lines, a.shards, t)
    mine = [lines[i] for i in range(len(lines)) if where[i] == a.shard]
    with open(a.out, "w") as f:
        f.write("".join(l + "\n" for l, _ in mine))
    digest = hashlib.sha256("\n".join(l for l, _ in lines).encode()).hexdigest()
    man = {"format": "mml-ci-shard/1", "commit": git_commit(), "shards": a.shards, "shard": a.shard, "list_sha256": digest,
           "list_count": len(lines), "list": [n for _, n in lines], "assigned": [n for _, n in mine],
           "unknown": [n for _, n in mine if "game/" + n not in t["tests"]],
           "estimate_seconds": round(load[a.shard]), "estimates_all": [round(x) for x in load]}
    if a.manifest:
        os.makedirs(os.path.dirname(os.path.abspath(a.manifest)), exist_ok=True)
        with open(a.manifest, "w") as f:
            json.dump(man, f, indent=1)
    print("shard %d of %d: %d of %d suites, estimated %.1f min (all shards: %s min)%s" % (
        a.shard, a.shards, len(mine), len(lines), load[a.shard] / 60, ", ".join("%.1f" % (x / 60) for x in load),
        ("; no timing yet for: " + ", ".join(man["unknown"])) if man["unknown"] else ""))
    return 0


# ------------------------------------------------------------------ the simulation gate -----------------------------------
def gate_jobs():
    """Exactly the jobs tools/sim_suite.py main() would run on this checkout (its own list, its rotating seeds), read by
    running main() up to the point where it would start them."""
    import sim_suite
    captured = {}

    def capture(godot, jobs, out, commit, workers):
        captured["jobs"], captured["commit"] = jobs, commit
        raise _Captured()

    argv, real = sys.argv, sim_suite.run_all
    tmp = ROOT / "out" / "_ci_plan"
    sys.argv = ["sim_suite.py", "--out", str(tmp), "--godot", "godot"]
    sim_suite.run_all = capture
    try:
        with contextlib.redirect_stdout(sys.stderr):      # main() prints its banner; stdout carries only the plan
            sim_suite.main()
    except _Captured:
        pass
    finally:
        sys.argv, sim_suite.run_all = argv, real
        try:
            tmp.rmdir()
        except OSError:
            pass
    if "jobs" not in captured:
        sys.exit("could not read the simulation gate's jobs from tools/sim_suite.py")
    return captured["jobs"], captured["commit"]


class _Captured(Exception):
    pass


def job_seconds(job, t):
    g = t["sim_gate"]
    if job["run"] in g:
        return g[job["run"]]
    d = t["defaults"]
    if job.get("kind", "sim") == "sim":
        return d["sim_seconds_per_day"] * job.get("days", 20) * (1.0 if job.get("record") else 0.9)
    return d["probe_seconds"]


def makespan(times, workers):
    slots = [0.0] * workers
    for x in sorted(times, reverse=True):
        i = slots.index(min(slots))
        slots[i] += x
    return max(slots) if slots else 0.0


def pack_gate(jobs, parts, workers, t, pairs):
    """Units (a determinism pair is one unit) longest first, each to the part whose estimated makespan grows least."""
    names = [j["run"] for j in jobs]
    secs = {j["run"]: job_seconds(j, t) for j in jobs}
    units, used = [], set()
    for a_, b_ in pairs:
        if a_ in secs and b_ in secs:
            units.append([a_, b_])
            used |= {a_, b_}
    units += [[n] for n in names if n not in used]
    units.sort(key=lambda u: (-sum(secs[n] for n in u), names.index(u[0])))
    plan = [[] for _ in range(parts)]
    for u in units:
        best = min(range(parts), key=lambda k: (makespan([secs[n] for n in plan[k] + u], workers), k))
        plan[best] += u
    return [{"part": k, "only": ",".join(p), "runs": len(p), "estimate_seconds": round(makespan([secs[n] for n in p], workers))}
            for k, p in enumerate(plan) if p]


def cmd_gate_plan(a):
    import sim_suite
    jobs, commit = gate_jobs()
    t = load_timings(a.timings)
    pairs = [(r, d) for r, d, _ in sim_suite.DET_PAIRS]
    plan = pack_gate(jobs, a.parts, a.jobs, t, pairs)
    every = sorted(j["run"] for j in jobs)
    assert sorted(n for p in plan for n in p["only"].split(",")) == every, "the plan must hold every run exactly once"
    print(json.dumps({"commit": commit, "runs": every, "parts": plan}, separators=(",", ":")))
    print("gate plan: %d runs in %d parts, estimated %s min" % (len(every), len(plan), ", ".join("%.0f" % (p["estimate_seconds"] / 60) for p in plan)),
          file=sys.stderr)
    return 0


def cmd_gate_record(a):
    out = Path(a.out)
    g = {}
    try:
        g = json.loads((out / "gate.json").read_text())
    except (OSError, ValueError):
        pass
    rec = {"format": "mml-sim-gate-part/1", "part": a.part, "only": a.only.split(","), "exit_code": a.code, "commit": git_commit(),
           "job_results": g.get("job_results", []), "simulation_seconds": (g.get("timing") or {}).get("simulations"),
           "part_result": g.get("result"), "runner": os.environ.get("RUNNER_NAME", ""), "cpus": os.cpu_count()}
    (out / ("part-%s.json" % a.part)).write_text(json.dumps(rec, indent=1))
    print("part %s: exit %s, %d job results" % (a.part, a.code, len(rec["job_results"])))
    return 0


def cmd_gate_merge(a):
    d = Path(a.dir)
    plan = json.loads(a.plan)
    commit = git_commit()
    problems, results, seen, sim_secs = [], {}, {}, []
    if plan.get("commit") != commit:
        problems.append("the plan was made on %s, this job runs %s" % (plan.get("commit"), commit))
    for p in plan["parts"]:
        f = d / ("part-%s.json" % p["part"])
        if not f.exists():
            problems.append("part %s: no record (the part did not finish: failed, cancelled or timed out)" % p["part"])
            continue
        r = json.loads(f.read_text())
        if r.get("commit") != commit:
            problems.append("part %s ran commit %s, not %s" % (p["part"], r.get("commit"), commit))
        if r.get("exit_code") not in (0, 1):
            problems.append("part %s: sim_suite.py exited %s (not a finding: the tool itself failed)" % (p["part"], r.get("exit_code")))
        if sorted(r.get("only", [])) != sorted(p["only"].split(",")):
            problems.append("part %s ran %s, the plan says %s" % (p["part"], r.get("only"), p["only"]))
        if r.get("simulation_seconds") is not None:
            sim_secs.append(r["simulation_seconds"])
        for jr in r.get("job_results", []):
            if jr["run"] in seen:
                problems.append("run %s reported by parts %s and %s" % (jr["run"], seen[jr["run"]], p["part"]))
            seen[jr["run"]] = p["part"]
            results[jr["run"]] = dict(jr, dir=str(d / jr["run"]))
    for n in plan["runs"]:
        if n not in results:
            problems.append("run %s: no result" % n)
        elif not (d / n / "run.log").exists():
            problems.append("run %s: its output directory was not gathered" % n)
    extra = sorted(set(results) - set(plan["runs"]))
    if extra:
        problems.append("runs not in the plan: %s" % ", ".join(extra))
    merged = {"format": "mml-sim-gate/1", "commit": commit, "job_results": [results[n] for n in plan["runs"] if n in results],
              "timing": {"simulations": max(sim_secs) if sim_secs else 0.0, "jobs": 0}, "merged_from_parts": len(plan["parts"])}
    (d / "gate.json").write_text(json.dumps(merged, indent=1))
    (d / "parts.json").write_text(json.dumps({"format": "mml-sim-gate-parts/1", "commit": commit, "plan": plan, "problems": problems,
                                              "part_simulation_seconds": sim_secs}, indent=1))
    for p in problems:
        print("::error::simulation gate parts: %s" % p)
    print("gate merge: %d of %d runs from %d parts; %d problems" % (len(results), len(plan["runs"]), len(plan["parts"]), len(problems)))
    return 1 if problems else 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--timings", default=str(TIMINGS))
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("tests-shard")
    s.add_argument("--list", required=True)
    s.add_argument("--shards", type=int, required=True)
    s.add_argument("--shard", type=int, required=True)
    s.add_argument("--out", required=True)
    s.add_argument("--manifest", default="")
    g = sub.add_parser("gate-plan")
    g.add_argument("--parts", type=int, default=4)
    g.add_argument("--jobs", type=int, default=4, help="parallel workers per part (a GitHub-hosted Linux runner has 4 CPUs)")
    r = sub.add_parser("gate-record")
    r.add_argument("--out", required=True)
    r.add_argument("--part", required=True)
    r.add_argument("--only", required=True)
    r.add_argument("--code", type=int, required=True)
    m = sub.add_parser("gate-merge")
    m.add_argument("--dir", required=True)
    m.add_argument("--plan", required=True, help="the gate-plan JSON")
    a = ap.parse_args(argv)
    if a.cmd == "tests-shard":
        if not 0 <= a.shard < a.shards:
            sys.exit("--shard must be 0 to --shards - 1")
        return cmd_tests_shard(a)
    return {"gate-plan": cmd_gate_plan, "gate-record": cmd_gate_record, "gate-merge": cmd_gate_merge}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
